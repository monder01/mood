const { setGlobalOptions } = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
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