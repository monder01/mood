const { setGlobalOptions } = require("firebase-functions");
const {
    onDocumentCreated,
    onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

setGlobalOptions({ maxInstances: 10 });

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

async function saveNotificationToUser({
    userId,
    title,
    body,
    type,
    senderId = "",
    receiverId = "",
    chatId = "",
    action = "",
}) {
    if (!userId || !title || !body || !type) return;

    await db
        .collection("users")
        .doc(userId)
        .collection("notifications")
        .add({
            title,
            body,
            type,
            senderId,
            receiverId,
            chatId,
            action,
            isRead: false,
            createdAt: FieldValue.serverTimestamp(),
        });
}

exports.sendChatNotification = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
        try {
            const snapshot = event.data;
            if (!snapshot) return;

            const messageData = snapshot.data();
            if (!messageData) return;

            const chatId = event.params.chatId;
            const senderId = messageData.senderId;
            const text = (messageData.text || "").toString().trim();

            if (!senderId || !text) return;

            const chatDoc = await db.collection("chats").doc(chatId).get();
            if (!chatDoc.exists) return;

            const chatData = chatDoc.data() || {};
            const participants = Array.isArray(chatData.participants)
                ? chatData.participants
                : [];

            if (participants.length < 2) return;

            const receiverId = participants.find((id) => id !== senderId);
            if (!receiverId) return;

            const senderDoc = await db.collection("users").doc(senderId).get();
            const senderData = senderDoc.exists ? senderDoc.data() : {};

            const senderName =
                `${senderData?.firstName || ""} ${senderData?.lastName || ""}`.trim() ||
                senderData?.userName ||
                "رسالة جديدة";

            const receiverDoc = await db.collection("users").doc(receiverId).get();
            if (!receiverDoc.exists) return;

            const receiverData = receiverDoc.data() || {};

            if (receiverData.activeChatId === chatId) {
                console.log("المستخدم داخل نفس المحادثة، لن يتم إرسال إشعار");
                return;
            }

            const title = "رسالة جديدة";
            const body = `${senderName} : ${text}`;
            const token = receiverData.messageToken || "";

            await saveNotificationToUser({
                userId: receiverId,
                title,
                body,
                type: "chat",
                senderId,
                receiverId,
                chatId,
            });

            if (!token) {
                console.log("لا يوجد messageToken للمستخدم:", receiverId);
                return;
            }

            const response = await messaging.send({
                token,
                notification: {
                    title,
                    body,
                },
                data: {
                    type: "chat",
                    chatId,
                    senderId,
                    receiverId,
                },
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                        },
                    },
                },
            });

            console.log("تم إرسال إشعار الرسالة بنجاح:", response);
        } catch (error) {
            console.error("خطأ أثناء إرسال إشعار الرسالة:", error);
        }
    }
);

exports.notifyLoginFromAnotherDevice = onDocumentUpdated(
    "users/{userId}",
    async (event) => {
        try {
            const before = event.data?.before?.data();
            const after = event.data?.after?.data();

            if (!before || !after) return;

            const userId = event.params.userId;

            const beforeSessionId = before.activeSessionId || "";
            const afterSessionId = after.activeSessionId || "";

            const beforeToken = before.messageToken || "";
            const afterToken = after.messageToken || "";

            const firstName = after.firstName || "";
            const lastName = after.lastName || "";
            const fullName = `${firstName} ${lastName}`.trim();

            if (beforeSessionId === afterSessionId) return;
            if (!beforeSessionId || !afterSessionId) return;
            if (!beforeToken) return;
            if (beforeToken === afterToken) return;

            const title = "تنبيه أمني";
            const body =
                "تم تسجيل الدخول إلى هذا الحساب من جهاز آخر 🚨\nإن لم تكن أنت الرجاء تسجيل الدخول وتغيير كلمة المرور";

            await saveNotificationToUser({
                userId,
                title,
                body,
                type: "security_login",
                receiverId: userId,
                action: "logged_in_elsewhere",
            });

            const response = await messaging.send({
                token: beforeToken,
                notification: {
                    title,
                    body,
                },
                data: {
                    type: "security_login",
                    action: "logged_in_elsewhere",
                    receiverId: userId,
                },
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                        },
                    },
                },
            });

            console.log(
                `تم إرسال إشعار تسجيل دخول من جهاز آخر للمستخدم ${fullName || userId}:`,
                response
            );
        } catch (error) {
            console.error("خطأ أثناء إرسال إشعار تسجيل الدخول من جهاز آخر:", error);
        }
    }
);

exports.sendNotificationToAllUsers = onCall(
    { region: "us-central1" },
    async (request) => {
        console.log("AUTH:", request.auth);

        if (!request.auth) {
            throw new HttpsError("unauthenticated", "يجب تسجيل الدخول أولاً");
        }

        const uid = request.auth.uid;

        const userDoc = await db.collection("users").doc(uid).get();

        if (!userDoc.exists) {
            throw new HttpsError("not-found", "المستخدم غير موجود");
        }

        const userData = userDoc.data() || {};

        if (userData.role !== "admin") {
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

        const usersSnapshot = await db.collection("users").get();
        const batch = db.batch();

        for (const doc of usersSnapshot.docs) {
            const userRef = db
                .collection("users")
                .doc(doc.id)
                .collection("notifications")
                .doc();

            batch.set(userRef, {
                title,
                body,
                type: "broadcast",
                senderId: uid,
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

        await messaging.send({
            topic: "all_users",
            notification: {
                title,
                body,
            },
            data: {
                type: "broadcast",
                senderId: uid,
                routePath,
                routeTitle,
                targetType,
                targetId,
                targetName,
                click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                    },
                },
            },
        });

        return {
            success: true,
            message: "تم إرسال الإشعار إلى جميع المستخدمين",
        };
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

            const senderId = newRequesters[0];
            if (!senderId) return;

            const senderDoc = await db.collection("users").doc(senderId).get();
            if (!senderDoc.exists) return;

            const senderData = senderDoc.data() || {};
            const senderName =
                `${senderData.firstName || ""} ${senderData.lastName || ""}`.trim() ||
                senderData.userName ||
                "مستخدم";

            const receiverDoc = await db.collection("users").doc(receiverId).get();
            if (!receiverDoc.exists) return;

            const receiverData = receiverDoc.data() || {};
            const token = receiverData.messageToken || "";

            const title = "طلب صداقة جديد";
            const body = `${senderName} أرسل لك طلب صداقة`;

            await saveNotificationToUser({
                userId: receiverId,
                title,
                body,
                type: "friend_request",
                senderId,
                receiverId,
            });

            if (token) {
                await messaging.send({
                    token,
                    notification: {
                        title,
                        body,
                    },
                    data: {
                        type: "friend_request",
                        senderId,
                        receiverId,
                        click_action: "FLUTTER_NOTIFICATION_CLICK",
                    },
                    android: {
                        priority: "high",
                        notification: {
                            sound: "default",
                        },
                    },
                    apns: {
                        payload: {
                            aps: {
                                sound: "default",
                            },
                        },
                    },
                });
            }

            console.log("تم إرسال إشعار طلب الصداقة إلى:", receiverId);
        } catch (error) {
            console.error("خطأ أثناء إرسال إشعار طلب الصداقة:", error);
        }
    }
);