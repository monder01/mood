import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final friendsRef = FirebaseFirestore.instance.collection('friends');

  /// إرسال طلب صداقة
  Future<void> sendFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    final currentDoc = friendsRef.doc(currentUserId);
    final targetDoc = friendsRef.doc(targetUserId);

    final currentSnapshot = await currentDoc.get();
    final targetSnapshot = await targetDoc.get();

    // إنشاء المستند إذا لم يكن موجودًا
    if (!currentSnapshot.exists) {
      await currentDoc.set({
        'userId': currentUserId,
        'friends': [],
        'friendRequests': [],
        'sentRequests': [targetUserId],
      });
    } else {
      final sent = List<String>.from(currentSnapshot['sentRequests'] ?? []);
      if (!sent.contains(targetUserId)) sent.add(targetUserId);
      await currentDoc.update({'sentRequests': sent});
    }

    if (!targetSnapshot.exists) {
      await targetDoc.set({
        'userId': targetUserId,
        'friends': [],
        'friendRequests': [currentUserId],
        'sentRequests': [],
      });
    } else {
      final requests = List<String>.from(
        targetSnapshot['friendRequests'] ?? [],
      );
      if (!requests.contains(currentUserId)) requests.add(currentUserId);
      await targetDoc.update({'friendRequests': requests});
    }
  }

  /// قبول طلب صداقة
  Future<void> acceptFriendRequest(
    String currentUserId,
    String senderUserId,
  ) async {
    final currentDoc = friendsRef.doc(currentUserId);
    final senderDoc = friendsRef.doc(senderUserId);

    final currentSnapshot = await currentDoc.get();
    final senderSnapshot = await senderDoc.get();

    final currentRequests = List<String>.from(
      currentSnapshot['friendRequests'] ?? [],
    );
    final currentFriends = List<String>.from(currentSnapshot['friends'] ?? []);
    final senderFriends = List<String>.from(senderSnapshot['friends'] ?? []);
    final senderSent = List<String>.from(senderSnapshot['sentRequests'] ?? []);

    if (currentRequests.contains(senderUserId)) {
      currentRequests.remove(senderUserId);
      currentFriends.add(senderUserId);
      await currentDoc.update({
        'friendRequests': currentRequests,
        'friends': currentFriends,
      });

      senderSent.remove(currentUserId);
      senderFriends.add(currentUserId);
      await senderDoc.update({
        'sentRequests': senderSent,
        'friends': senderFriends,
      });
    }
  }

  /// رفض طلب صداقة
  Future<void> rejectFriendRequest(
    String currentUserId,
    String senderUserId,
  ) async {
    final currentDoc = friendsRef.doc(currentUserId);
    final senderDoc = friendsRef.doc(senderUserId);

    final currentSnapshot = await currentDoc.get();
    final senderSnapshot = await senderDoc.get();

    final currentRequests = List<String>.from(
      currentSnapshot['friendRequests'] ?? [],
    );
    final senderSent = List<String>.from(senderSnapshot['sentRequests'] ?? []);

    if (currentRequests.contains(senderUserId)) {
      currentRequests.remove(senderUserId);
      await currentDoc.update({'friendRequests': currentRequests});

      senderSent.remove(currentUserId);
      await senderDoc.update({'sentRequests': senderSent});
    }
  }

  /// إزالة صديق
  Future<void> removeFriend(String currentUserId, String friendUserId) async {
    final currentDoc = friendsRef.doc(currentUserId);
    final friendDoc = friendsRef.doc(friendUserId);

    final currentSnapshot = await currentDoc.get();
    final friendSnapshot = await friendDoc.get();

    final currentFriends = List<String>.from(currentSnapshot['friends'] ?? []);
    final friendFriends = List<String>.from(friendSnapshot['friends'] ?? []);

    if (currentFriends.contains(friendUserId)) {
      currentFriends.remove(friendUserId);
      await currentDoc.update({'friends': currentFriends});

      friendFriends.remove(currentUserId);
      await friendDoc.update({'friends': friendFriends});
    }
  }

  /// تحقق من حالة الصداقة
  /// ممكن ترجع القيم: "friends", "requestSent", "requestReceived", "none"
  Future<String> checkFriendStatus(
    String currentUserId,
    String otherUserId,
  ) async {
    final snapshot = await friendsRef.doc(currentUserId).get();
    if (!snapshot.exists) return "none";

    final friends = List<String>.from(snapshot['friends'] ?? []);
    final sentRequests = List<String>.from(snapshot['sentRequests'] ?? []);
    final friendRequests = List<String>.from(snapshot['friendRequests'] ?? []);

    if (friends.contains(otherUserId)) return "friends";
    if (sentRequests.contains(otherUserId)) return "requestSent";
    if (friendRequests.contains(otherUserId)) return "requestReceived";
    return "none";
  }

  /// دالة لإلغاء الطلب المرسل
  Future<void> cancelSentRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    final currentDoc = friendsRef.doc(currentUserId);
    final targetDoc = friendsRef.doc(targetUserId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(currentDoc);
      final targetSnapshot = await transaction.get(targetDoc);

      final sentRequests = List<String>.from(
        currentSnapshot['sentRequests'] ?? [],
      );
      final friendRequests = List<String>.from(
        targetSnapshot['friendRequests'] ?? [],
      );

      if (sentRequests.contains(targetUserId)) {
        sentRequests.remove(targetUserId);
        friendRequests.remove(currentUserId);

        transaction.update(currentDoc, {'sentRequests': sentRequests});
        transaction.update(targetDoc, {'friendRequests': friendRequests});
      }
    });
  }
}
