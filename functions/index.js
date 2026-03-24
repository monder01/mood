const { setGlobalOptions } = require("firebase-functions");
const {
    onDocumentCreated,
    onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onValueWritten } = require("firebase-functions/v2/database");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

setGlobalOptions({ maxInstances: 10 });

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

const USER_COLLECTION = "users";
const ADMIN_COLLECTION = "admins";
const USER_BROADCAST_TOPIC = "all_users";

// =========================
// Helpers
// =========================

async function clearInvalidToken(collectionName, docId) {
    if (!collectionName || !docId) return;

    try {
        await db.collection(collectionName).doc(docId).set(
            {
                messageToken: "",
            },
            { merge: true }
        );
        console.log(`تم حذف التوكن غير الصالح من ${collectionName}/${docId}`);
    } catch (error) {
        console.error("خطأ أثناء حذف التوكن غير الصالح:", error);
    }
}

async function sendPushToToken({
    token,
    collectionName,
    docId = "",
    title,
    body,
    data = {},
}) {
    if (!token || !title || !body) return null;

    try {
        const payloadData = {};

        for (const key of Object.keys(data)) {
            payloadData[key] = data[key] == null ? "" : String(data[key]);
        }

        const response = await messaging.send({
            token,
            notification: { title, body },
            data: payloadData,
            android: {
                priority: "high",
                notification: { sound: "default" },
            },
            apns: {
                payload: {
                    aps: { sound: "default" },
                },
            },
        });

        return response;
    } catch (error) {
        console.error("خطأ أثناء إرسال الإشعار:", error);

        const errorCode = error?.code || "";
        if (
            errorCode === "messaging/registration-token-not-registered" ||
            errorCode === "messaging/invalid-registration-token"
        ) {
            await clearInvalidToken(collectionName, docId);
        }

        return null;
    }
}

async function saveNotification({
    collectionName,
    docId,
    title,
    body,
    type,
    senderId = "",
    receiverId = "",
    chatId = "",
    action = "",
    routePath = "",
    routeTitle = "",
    targetType = "",
    targetId = "",
    targetName = "",
}) {
    if (!collectionName || !docId || !title || !body || !type) return;

    await db
        .collection(collectionName)
        .doc(docId)
        .collection("notifications")
        .add({
            title,
            body,
            type,
            senderId,
            receiverId,
            chatId,
            action,
            routePath,
            routeTitle,
            targetType,
            targetId,
            targetName,
            isRead: false,
            createdAt: FieldValue.serverTimestamp(),
        });
}

async function getDocData(collectionName, docId) {
    const doc = await db.collection(collectionName).doc(docId).get();
    if (!doc.exists) return null;
    return { id: doc.id, data: doc.data() || {} };
}

function buildDisplayName(data, fallback = "مستخدم") {
    return (
        `${data?.firstName || ""} ${data?.lastName || ""}`.trim() ||
        data?.userName ||
        fallback
    );
}

async function handleChatNotification({
    chatCollection,
    peopleCollection,
    saveCollection,
    activeChatField = "activeChatId",
    routePath,
    routeTitle,
    fallbackName,
    logPrefix,
    event,
}) {
    try {
        const snapshot = event.data;
        if (!snapshot) return;

        const messageData = snapshot.data();
        if (!messageData) return;

        const chatId = event.params.chatId;
        const senderId = (messageData.senderId || "").toString().trim();
        const text = (messageData.text || "").toString().trim();

        if (!senderId || !text) return;

        const chatDoc = await db.collection(chatCollection).doc(chatId).get();
        if (!chatDoc.exists) return;

        const chatData = chatDoc.data() || {};
        const participants = Array.isArray(chatData.participants)
            ? chatData.participants
            : [];

        if (!participants.length) return;

        const receiverIds = participants.filter((id) => id && id !== senderId);
        if (!receiverIds.length) return;

        const senderResult = await getDocData(peopleCollection, senderId);
        const senderData = senderResult?.data || {};
        const senderName = buildDisplayName(senderData, fallbackName);

        const title = "رسالة جديدة";
        const body = `${senderName} : ${text}`;

        for (const receiverId of receiverIds) {
            const receiverResult = await getDocData(peopleCollection, receiverId);
            if (!receiverResult) continue;

            const receiverData = receiverResult.data || {};
            const token = (receiverData.messageToken || "").toString().trim();

            await saveNotification({
                collectionName: saveCollection,
                docId: receiverId,
                title,
                body,
                type: "chat",
                senderId,
                receiverId,
                chatId,
                routePath,
                routeTitle,
                targetType: "chat",
                targetId: chatId,
                targetName: senderName,
            });

            if ((receiverData[activeChatField] || "") === chatId) {
                console.log(`${logPrefix}: المستلم داخل نفس المحادثة، لن يتم إرسال إشعار خارجي`);
                continue;
            }

            if (!token) {
                console.log(`${logPrefix}: لا يوجد messageToken للمستلم:`, receiverId);
                continue;
            }

            const response = await sendPushToToken({
                token,
                collectionName: saveCollection,
                docId: receiverId,
                title,
                body,
                data: {
                    type: "chat",
                    chatId,
                    senderId,
                    receiverId,
                    routePath,
                    routeTitle,
                    targetType: "chat",
                    targetId: chatId,
                    targetName: senderName,
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                },
            });

            if (response) {
                console.log(`${logPrefix}: تم إرسال إشعار الرسالة بنجاح:`, response);
            }
        }
    } catch (error) {
        console.error(`${logPrefix}: خطأ أثناء إرسال إشعار الرسالة:`, error);
    }
}

async function handleSecurityLoginNotification({
    collectionName,
    paramName,
    displayFallback,
    routePath = "/my-account",
    event,
    logPrefix,
}) {
    try {
        const before = event.data?.before?.data();
        const after = event.data?.after?.data();

        if (!before || !after) return;

        const docId = event.params[paramName];

        const beforeSessionId = (before.activeSessionId || "").toString().trim();
        const afterSessionId = (after.activeSessionId || "").toString().trim();

        const beforeToken = (before.messageToken || "").toString().trim();
        const afterToken = (after.messageToken || "").toString().trim();

        const fullName = buildDisplayName(after, displayFallback);

        if (beforeSessionId === afterSessionId) return;
        if (!beforeSessionId || !afterSessionId) return;
        if (!beforeToken) return;
        if (beforeToken === afterToken) return;

        const title = "تنبيه أمني";
        const body =
            collectionName === ADMIN_COLLECTION
                ? "تم تسجيل الدخول إلى حساب الأدمن هذا من جهاز آخر 🚨\nإن لم تكن أنت الرجاء تسجيل الدخول وتغيير كلمة المرور"
                : "تم تسجيل الدخول إلى هذا الحساب من جهاز آخر 🚨\nإن لم تكن أنت الرجاء تسجيل الدخول وتغيير كلمة المرور";

        await saveNotification({
            collectionName,
            docId,
            title,
            body,
            type: "security_login",
            receiverId: docId,
            action: "logged_in_elsewhere",
            routePath,
            routeTitle: "تنبيه أمني",
            targetType: "security",
            targetId: docId,
            targetName: fullName,
        });

        const response = await sendPushToToken({
            token: beforeToken,
            collectionName,
            docId,
            title,
            body,
            data: {
                type: "security_login",
                action: "logged_in_elsewhere",
                receiverId: docId,
                routePath,
                routeTitle: "تنبيه أمني",
                targetType: "security",
                targetId: docId,
                targetName: fullName,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
        });

        if (response) {
            console.log(`${logPrefix}: تم إرسال إشعار تنبيه أمني بنجاح:`, response);
        }
    } catch (error) {
        console.error(`${logPrefix}: خطأ أثناء إرسال إشعار تسجيل الدخول:`, error);
    }
}

async function handlePresenceSync({ collectionName, event }) {
    const uid = event.params.uid;
    const data = event.data.after.val();

    if (!data) return null;

    return db.collection(collectionName).doc(uid).set(
        {
            isOnline: data.isOnline === true,
            lastSeen: FieldValue.serverTimestamp(),
        },
        { merge: true }
    );
}

// =========================
// User App Functions
// =========================

exports.sendUserChatNotification = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
        await handleChatNotification({
            chatCollection: "chats",
            peopleCollection: USER_COLLECTION,
            saveCollection: USER_COLLECTION,
            activeChatField: "activeChatId",
            routePath: "/chat",
            routeTitle: "المحادثة",
            fallbackName: "رسالة جديدة",
            logPrefix: "User Chat",
            event,
        });
    }
);

exports.notifyUserLoginFromAnotherDevice = onDocumentUpdated(
    "users/{userId}",
    async (event) => {
        await handleSecurityLoginNotification({
            collectionName: USER_COLLECTION,
            paramName: "userId",
            displayFallback: "المستخدم",
            routePath: "/my-account",
            logPrefix: "User Security",
            event,
        });
    }
);

exports.sendFriendRequestNotification = onDocumentUpdated(
    "friends/{userId}",
    async (event) => {
        try {
            const before = event.data?.before?.data();
            const after = event.data?.after?.data();

            if (!before || !after) return;

            const receiverId = event.params.userId;

            const beforeRequests = Array.isArray(before.friendRequests)
                ? before.friendRequests
                : [];

            const afterRequests = Array.isArray(after.friendRequests)
                ? after.friendRequests
                : [];

            if (afterRequests.length <= beforeRequests.length) return;

            const newRequesters = afterRequests.filter(
                (id) => !beforeRequests.includes(id)
            );

            if (!newRequesters.length) return;

            for (const senderId of newRequesters) {
                if (!senderId) continue;

                const senderResult = await getDocData(USER_COLLECTION, senderId);
                if (!senderResult) continue;

                const senderName = buildDisplayName(senderResult.data, "مستخدم");

                const receiverResult = await getDocData(USER_COLLECTION, receiverId);
                if (!receiverResult) continue;

                const receiverData = receiverResult.data || {};
                const token = (receiverData.messageToken || "").toString().trim();

                const title = "طلب صداقة جديد";
                const body = `${senderName} أرسل لك طلب صداقة`;

                await saveNotification({
                    collectionName: USER_COLLECTION,
                    docId: receiverId,
                    title,
                    body,
                    type: "friend_request",
                    senderId,
                    receiverId,
                    routePath: "/fellows",
                    routeTitle: "طلبات الصداقة",
                    targetType: "friend_request",
                    targetId: senderId,
                    targetName: senderName,
                });

                if (token) {
                    const response = await sendPushToToken({
                        token,
                        collectionName: USER_COLLECTION,
                        docId: receiverId,
                        title,
                        body,
                        data: {
                            type: "friend_request",
                            senderId,
                            receiverId,
                            routePath: "/fellows",
                            routeTitle: "طلبات الصداقة",
                            targetType: "friend_request",
                            targetId: senderId,
                            targetName: senderName,
                            click_action: "FLUTTER_NOTIFICATION_CLICK",
                        },
                    });

                    if (response) {
                        console.log("Friend Request: تم إرسال إشعار طلب الصداقة إلى:", receiverId);
                    }
                }
            }
        } catch (error) {
            console.error("Friend Request: خطأ أثناء إرسال إشعار طلب الصداقة:", error);
        }
    }
);

exports.syncUserPresenceToFirestore = onValueWritten(
    "/status/{uid}",
    async (event) => {
        return handlePresenceSync({
            collectionName: USER_COLLECTION,
            event,
        });
    }
);

// =========================
// Admin App Functions
// =========================

exports.sendAdminChatNotification = onDocumentCreated(
    "adminChats/{chatId}/messages/{messageId}",
    async (event) => {
        await handleChatNotification({
            chatCollection: "adminChats",
            peopleCollection: ADMIN_COLLECTION,
            saveCollection: ADMIN_COLLECTION,
            activeChatField: "activeChatId",
            routePath: "/admin-chat",
            routeTitle: "محادثة الأدمن",
            fallbackName: "رسالة جديدة",
            logPrefix: "Admin Chat",
            event,
        });
    }
);

exports.notifyAdminLoginFromAnotherDevice = onDocumentUpdated(
    "admins/{adminId}",
    async (event) => {
        await handleSecurityLoginNotification({
            collectionName: ADMIN_COLLECTION,
            paramName: "adminId",
            displayFallback: "الأدمن",
            routePath: "/my-account",
            logPrefix: "Admin Security",
            event,
        });
    }
);

exports.sendBroadcastToUsers = onCall(
    { region: "us-central1" },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً");
        }

        const adminId = request.auth.uid;

        const adminDoc = await db.collection(ADMIN_COLLECTION).doc(adminId).get();
        if (!adminDoc.exists) {
            throw new HttpsError("permission-denied", "غير مصرح لك");
        }

        const title = (request.data.title || "").toString().trim();
        const body = (request.data.body || "").toString().trim();
        const routePath = (request.data.routePath || "").toString().trim();
        const routeTitle = (request.data.routeTitle || "").toString().trim();
        const targetType = (request.data.targetType || "").toString().trim();
        const targetId = (request.data.targetId || "").toString().trim();
        const targetName = (request.data.targetName || "").toString().trim();

        if (!title || !body) {
            throw new HttpsError("invalid-argument", "العنوان والنص مطلوبان");
        }

        const usersSnapshot = await db.collection(USER_COLLECTION).get();
        const docs = usersSnapshot.docs;
        const batchSize = 450;

        for (let i = 0; i < docs.length; i += batchSize) {
            const batch = db.batch();
            const chunk = docs.slice(i, i + batchSize);

            for (const doc of chunk) {
                const userRef = db
                    .collection(USER_COLLECTION)
                    .doc(doc.id)
                    .collection("notifications")
                    .doc();

                batch.set(userRef, {
                    title,
                    body,
                    type: "broadcast",
                    senderId: adminId,
                    receiverId: doc.id,
                    chatId: "",
                    action: "",
                    routePath,
                    routeTitle,
                    targetType,
                    targetId,
                    targetName,
                    isRead: false,
                    createdAt: FieldValue.serverTimestamp(),
                });
            }

            await batch.commit();
        }

        await messaging.send({
            topic: USER_BROADCAST_TOPIC,
            notification: { title, body },
            data: {
                type: "broadcast",
                senderId: String(adminId),
                routePath: String(routePath),
                routeTitle: String(routeTitle),
                targetType: String(targetType),
                targetId: String(targetId),
                targetName: String(targetName),
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: { sound: "default" },
            },
            apns: {
                payload: {
                    aps: { sound: "default" },
                },
            },
        });

        return {
            success: true,
            message: "تم إرسال الإشعار إلى جميع المستخدمين",
        };
    }
);

exports.syncAdminPresenceToFirestore = onValueWritten(
    "/adminStatus/{uid}",
    async (event) => {
        return handlePresenceSync({
            collectionName: ADMIN_COLLECTION,
            event,
        });
    }
);