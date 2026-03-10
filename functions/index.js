const { setGlobalOptions } = require("firebase-functions");
const {
    onDocumentCreated,
    onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
setGlobalOptions({ maxInstances: 10 });

initializeApp();

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
            const text = messageData.text || "";

            if (!senderId || !text) return;

            const db = getFirestore();

            const chatDoc = await db.collection("chats").doc(chatId).get();
            if (!chatDoc.exists) return;

            const chatData = chatDoc.data();
            const participants = chatData.participants || [];

            if (!Array.isArray(participants) || participants.length < 2) return;

            const receiverId = participants.find((id) => id !== senderId);
            if (!receiverId) return;

            const senderDoc = await db.collection("users").doc(senderId).get();
            const senderData = senderDoc.exists ? senderDoc.data() : {};

            const senderName =
                `${senderData.firstName || ""} ${senderData.lastName || ""}`.trim() ||
                "رسالة جديدة";

            const receiverDoc = await db.collection("users").doc(receiverId).get();
            if (!receiverDoc.exists) return;

            const receiverData = receiverDoc.data();

            if (receiverData.activeChatId === chatId) {
                console.log("المستخدم داخل نفس المحادثة، لن يتم إرسال إشعار");
                return;
            }

            const token = receiverData.messageToken;

            if (!token) {
                console.log("لا يوجد messageToken للمستخدم:", receiverId);
                return;
            }

            const payload = {
                token: token,
                notification: {
                    title: "رسالة جديدة",
                    body: senderName + " : " + text,
                },
                data: {
                    type: "chat",
                    chatId: chatId,
                    senderId: senderId,
                    receiverId: receiverId,
                },
                android: {
                    priority: "high",
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                        },
                    },
                },
            };

            const response = await getMessaging().send(payload);
            console.log("تم إرسال الإشعار بنجاح:", response);
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

            const beforeSessionId = before.activeSessionId || "";
            const afterSessionId = after.activeSessionId || "";

            const beforeToken = before.messageToken || "";
            const afterToken = after.messageToken || "";

            const firstName = after.firstName || "";
            const lastName = after.lastName || "";
            const fullName = `${firstName} ${lastName}`.trim();

            // إذا لم تتغير الجلسة، لا تفعل شيئًا
            if (beforeSessionId === afterSessionId) return;

            // إذا كانت الجلسة القديمة فارغة، فهذا غالبًا أول تسجيل دخول
            if (!beforeSessionId || !afterSessionId) return;

            // إذا كان التوكن القديم غير موجود، لا يوجد جهاز نرسل له
            if (!beforeToken) return;

            // إذا كان نفس التوكن، فالغالب أنه نفس الجهاز وليس جهازًا آخر
            if (beforeToken === afterToken) return;

            const payload = {
                token: beforeToken,
                notification: {
                    title: "تنبيه أمني",
                    body: "تم تسجيل الدخول إلى هذا الحساب من جهاز آخر",
                },
                data: {
                    type: "security_login",
                    action: "logged_in_elsewhere",
                },
                android: {
                    priority: "high",
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                        },
                    },
                },
            };

            const response = await getMessaging().send(payload);
            console.log(
                `تم إرسال إشعار تسجيل دخول من جهاز آخر للمستخدم ${fullName || event.params.userId}:`,
                response
            );
        } catch (error) {
            console.error("خطأ أثناء إرسال إشعار تسجيل الدخول من جهاز آخر:", error);
        }
    }
);