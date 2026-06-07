const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onClipboardCreated = onDocumentCreated(
  {
    document: "users/{roomId}/clipboards/{clipId}",
    region: "asia-northeast3",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const { roomId } = event.params;
    const clip = snapshot.data() || {};
    const encryptedText = clip.content;
    const uploaderDevice = clip.deviceName || "Unknown Device";
    const uploaderDeviceId = clip.deviceId || null;

    if (!encryptedText || typeof encryptedText !== "string") return;

    const tokensSnapshot = await admin
      .firestore()
      .collection("users")
      .doc(roomId)
      .collection("tokens")
      .get();

    const targets = [];
    tokensSnapshot.forEach((tokenDoc) => {
      if (uploaderDeviceId) {
        if (tokenDoc.id === uploaderDeviceId) return;
      } else if (tokenDoc.id === uploaderDevice) {
        return;
      }

      const token = tokenDoc.get("token");
      if (!token || typeof token !== "string") return;
      if (tokenDoc.get("notificationsEnabled") === false) return;

      targets.push({
        ref: tokenDoc.ref,
        message: {
          token,
          data: {
            title: "Clipboard synced",
            body: `${uploaderDevice} sent clipboard data.`,
            action: "open_clipboard",
            text: encryptedText,
          },
        },
      });
    });

    if (targets.length === 0) return;

    const responses = await Promise.allSettled(
      targets.map((target) => admin.messaging().send(target.message)),
    );

    const invalidTokenDeletes = [];
    responses.forEach((response, index) => {
      if (response.status === "fulfilled") return;

      const code = response.reason && response.reason.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        invalidTokenDeletes.push(targets[index].ref.delete());
      }
    });

    await Promise.allSettled(invalidTokenDeletes);
  },
);
