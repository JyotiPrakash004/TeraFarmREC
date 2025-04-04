import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Main Community Page that shows a list of channels.
class CommunityPage extends StatefulWidget {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Controllers for creating a channel.
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _channelDescController = TextEditingController();
  File? _newChannelImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatgram Channels'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('channels')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final channels = snapshot.data!.docs;
          return ListView.builder(
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              final channelId = channel.id;
              final channelData = channel.data() as Map<String, dynamic>?;

              if (channelData == null) return const SizedBox.shrink();

              final channelName = channelData['name'] ?? 'No Name';
              final members = (channelData['members'] as List<dynamic>?) ?? [];
              final currentUserId = _auth.currentUser?.uid;
              final bool isMember =
                  currentUserId != null && members.contains(currentUserId);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.group),
                ),
                title: Text(channelName),
                subtitle:
                    isMember
                        ? const Text('You are a member')
                        : const Text('Tap to join'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    if (!isMember && currentUserId != null) {
                      // Join channel.
                      await _firestore
                          .collection('channels')
                          .doc(channelId)
                          .update({
                            'members': FieldValue.arrayUnion([currentUserId]),
                          });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMember ? Colors.grey : Colors.blue,
                  ),
                  child: Text(isMember ? 'Joined' : 'Join'),
                ),
                onTap: () {
                  if (isMember) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChannelChatPage(
                              channelId: channelId,
                              channelName: channelName,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please join the channel first.'),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChannelDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateChannelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickChannelImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        _newChannelImage != null
                            ? FileImage(_newChannelImage!)
                            : null,
                    child:
                        _newChannelImage == null
                            ? const Icon(Icons.camera_alt, size: 40)
                            : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _channelNameController,
                  decoration: const InputDecoration(labelText: 'Group Name'),
                ),
                TextField(
                  controller: _channelDescController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearChannelCreationFields();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final channelName = _channelNameController.text.trim();
                final channelDesc = _channelDescController.text.trim();
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                String profileUrl = "";

                if (_newChannelImage != null) {
                  profileUrl = await _uploadChannelImage(_newChannelImage!);
                }

                if (channelName.isNotEmpty && currentUserId != null) {
                  try {
                    await FirebaseFirestore.instance.collection('channels').add(
                      {
                        'name': channelName,
                        'description': channelDesc,
                        'profileUrl': profileUrl,
                        'createdBy': currentUserId,
                        'members': [currentUserId],
                        'admins': [currentUserId],
                        'createdAt': FieldValue.serverTimestamp(),
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Channel created successfully!'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating channel: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Channel name cannot be empty.'),
                    ),
                  );
                }

                _clearChannelCreationFields();
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _clearChannelCreationFields() {
    _channelNameController.clear();
    _channelDescController.clear();
    setState(() {
      _newChannelImage = null;
    });
  }

  Future<void> _pickChannelImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _newChannelImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadChannelImage(File file) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('channel_profiles')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}

///
/// Channel Chat Page with Menu Options, Attachment, and Edit Group for Leader
///
class ChannelChatPage extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelChatPage({
    Key? key,
    required this.channelId,
    required this.channelName,
  }) : super(key: key);

  @override
  State<ChannelChatPage> createState() => _ChannelChatPageState();
}

class _ChannelChatPageState extends State<ChannelChatPage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('channels')
                    .doc(widget.channelId)
                    .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final String? leaderId = data['createdBy'] as String?;
              return FutureBuilder<DocumentSnapshot>(
                future:
                    leaderId != null
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(leaderId)
                            .get()
                        : Future.value(null),
                builder: (context, leaderSnapshot) {
                  String leaderName = leaderId ?? 'Unknown';
                  if (leaderSnapshot.hasData) {
                    final leaderData =
                        leaderSnapshot.data!.data() as Map<String, dynamic>? ??
                        {};
                    leaderName =
                        leaderData['username'] ?? leaderId ?? 'Unknown';
                  }
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'about') {
                        _showAboutDialog();
                      } else if (value == 'leave') {
                        _leaveGroup();
                      } else if (value == 'edit') {
                        _showEditGroupDialog();
                      } else if (value == 'manage') {
                        // Navigate to the Channel Management Page.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ChannelManagementPage(
                                  channelId: widget.channelId,
                                  channelName: widget.channelName,
                                ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) {
                      List<PopupMenuEntry<String>> items = [
                        PopupMenuItem<String>(
                          value: 'leader',
                          enabled: false,
                          child: Text("Leader: $leaderName"),
                        ),
                        PopupMenuItem<String>(
                          value: 'about',
                          child: const Text("About"),
                        ),
                        PopupMenuItem<String>(
                          value: 'leave',
                          child: const Text("Leave Group"),
                        ),
                      ];
                      if (currentUserId == leaderId) {
                        // Only the leader sees these options.
                        items.insert(
                          1,
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text("Edit Group"),
                          ),
                        );
                        items.insert(
                          2,
                          const PopupMenuItem<String>(
                            value: 'manage',
                            child: Text("Manage Users"),
                          ),
                        );
                      }
                      return items;
                    },
                    icon: const Icon(Icons.more_vert),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildChatMessages(currentUserId)),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatMessages(String? currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('channels')
              .doc(widget.channelId)
              .collection('messages')
              .orderBy('sentAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final message = messageData['text'] ?? '';
            final senderId = messageData['senderId'] ?? 'Unknown';
            final imageUrl = messageData['imageUrl'] as String?;
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(senderId)
                      .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox.shrink();
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final username = userData['username'] ?? 'Unknown User';
                final isCurrentUser = senderId == currentUserId;
                return Align(
                  alignment:
                      isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isCurrentUser
                              ? Colors.green.shade100
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isCurrentUser
                                    ? Colors.green.shade800
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        imageUrl != null
                            ? Image.network(imageUrl, width: 200)
                            : Text(message),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    final TextEditingController messageController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      child: Row(
        children: [
          // Attachment Button.
          IconButton(
            icon: const Icon(Icons.attachment, color: Colors.deepPurple),
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: const InputDecoration(hintText: 'Enter message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.deepPurple),
            onPressed: () async {
              final text = messageController.text.trim();
              final currentUser = FirebaseAuth.instance.currentUser;
              if (text.isNotEmpty && currentUser != null) {
                await FirebaseFirestore.instance
                    .collection('channels')
                    .doc(widget.channelId)
                    .collection('messages')
                    .add({
                      'text': text,
                      'senderId': currentUser.uid,
                      'sentAt': FieldValue.serverTimestamp(),
                    });
                messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String downloadUrl = await _uploadFile(imageFile);
      await FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.channelId)
          .collection('messages')
          .add({
            'imageUrl': downloadUrl,
            'senderId': FirebaseAuth.instance.currentUser!.uid,
            'sentAt': FieldValue.serverTimestamp(),
          });
    }
  }

  Future<String> _uploadFile(File file) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => ChannelAboutDialog(channelId: widget.channelId),
    );
  }

  void _leaveGroup() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.channelId)
          .update({
            'members': FieldValue.arrayRemove([currentUser.uid]),
            'admins': FieldValue.arrayRemove([currentUser.uid]),
          });
      Navigator.pop(context);
    }
  }

  void _showEditGroupDialog() {
    showDialog(
      context: context,
      builder: (_) => EditGroupDialog(channelId: widget.channelId),
    );
  }
}

///
/// Channel About Dialog shows leader, description, and members info.
///
class ChannelAboutDialog extends StatelessWidget {
  final String channelId;

  const ChannelAboutDialog({Key? key, required this.channelId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('channels')
              .doc(channelId)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AlertDialog(
            title: Text("About Group"),
            content: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String? leaderId = data['createdBy'] as String?;
        final List<dynamic> members = data['members'] as List<dynamic>? ?? [];

        return AlertDialog(
          title: const Text("About Group"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future:
                      leaderId != null
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(leaderId)
                              .get()
                          : Future.value(null),
                  builder: (context, leaderSnapshot) {
                    String leaderName = leaderId ?? 'Unknown';
                    if (leaderSnapshot.hasData) {
                      final leaderData =
                          leaderSnapshot.data!.data()
                              as Map<String, dynamic>? ??
                          {};
                      leaderName =
                          leaderData['username'] ?? leaderId ?? 'Unknown';
                    }
                    return Text(
                      "Leader: $leaderName",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  "Members:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                ...members.map((memberId) {
                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(memberId)
                            .get(),
                    builder: (context, memberSnapshot) {
                      String memberName = memberId.toString();
                      if (memberSnapshot.hasData) {
                        final memberData =
                            memberSnapshot.data!.data()
                                as Map<String, dynamic>? ??
                            {};
                        memberName =
                            memberData['username'] ?? memberId.toString();
                      }
                      return Text(memberName);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

///
/// Dialog for Leader to Edit Group Details
///
class EditGroupDialog extends StatefulWidget {
  final String channelId;
  const EditGroupDialog({Key? key, required this.channelId}) : super(key: key);

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  File? _newProfileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('channels')
            .doc(widget.channelId)
            .get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    _nameController.text = data['name'] ?? '';
    _descController.text = data['description'] ?? '';
  }

  Future<String?> _uploadProfileImage(File file) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('channel_profiles')
        .child(
          '${widget.channelId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    String? profileUrl;
    if (_newProfileImage != null) {
      profileUrl = await _uploadProfileImage(_newProfileImage!);
    }
    await FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelId)
        .update({
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          if (profileUrl != null) 'profileUrl': profileUrl,
        });
    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Group"),
      content:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            _newProfileImage != null
                                ? FileImage(_newProfileImage!)
                                : null,
                        child:
                            _newProfileImage == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Group Name",
                      ),
                    ),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),
                  ],
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(onPressed: _saveChanges, child: const Text("Save")),
      ],
    );
  }
}

///
/// Channel Management Page (For Leader)
/// Allows leader to remove members and add new ones.
///
class ChannelManagementPage extends StatelessWidget {
  final String channelId;
  final String channelName;

  const ChannelManagementPage({
    Key? key,
    required this.channelId,
    required this.channelName,
  }) : super(key: key);

  /// Dialog to add a new member by entering a user ID.
  void _showAddUserDialog(BuildContext context) {
    final TextEditingController userIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: userIdController,
            decoration: const InputDecoration(labelText: 'Enter User ID'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUserId = userIdController.text.trim();
                if (newUserId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('channels')
                      .doc(channelId)
                      .update({
                        'members': FieldValue.arrayUnion([newUserId]),
                      });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: Text('Manage: $channelName')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('channels')
                .doc(channelId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final channelData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final List<dynamic> members =
              channelData['members'] as List<dynamic>? ?? [];
          final String? leaderId = channelData['createdBy'] as String?;
          final List<dynamic> admins =
              channelData['admins'] as List<dynamic>? ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leader Header
              if (leaderId != null)
                FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(leaderId)
                          .get(),
                  builder: (context, leaderSnapshot) {
                    String leaderName = leaderId;
                    if (leaderSnapshot.hasData) {
                      final leaderData =
                          leaderSnapshot.data!.data()
                              as Map<String, dynamic>? ??
                          {};
                      leaderName = leaderData['username'] ?? leaderId;
                    }
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(leaderName),
                      subtitle: const Text('Leader'),
                    );
                  },
                ),
              const Divider(),
              // Members List (excluding leader)
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final memberId = members[index] as String;
                    if (memberId == leaderId) return const SizedBox.shrink();
                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(memberId)
                              .get(),
                      builder: (context, userSnapshot) {
                        String memberName = memberId;
                        if (userSnapshot.hasData) {
                          final userData =
                              userSnapshot.data!.data()
                                  as Map<String, dynamic>? ??
                              {};
                          memberName = userData['username'] ?? memberId;
                        }
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(memberName),
                          subtitle:
                              admins.contains(memberId)
                                  ? const Text('Admin')
                                  : null,
                          trailing:
                              currentUserId == leaderId
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('channels')
                                              .doc(channelId)
                                              .update({
                                                'members':
                                                    FieldValue.arrayRemove([
                                                      memberId,
                                                    ]),
                                                'admins':
                                                    FieldValue.arrayRemove([
                                                      memberId,
                                                    ]),
                                              });
                                        },
                                      ),
                                      if (!admins.contains(memberId))
                                        IconButton(
                                          icon: const Icon(
                                            Icons.star_border,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('channels')
                                                .doc(channelId)
                                                .update({
                                                  'admins':
                                                      FieldValue.arrayUnion([
                                                        memberId,
                                                      ]),
                                                });
                                          },
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('channels')
                                                .doc(channelId)
                                                .update({
                                                  'admins':
                                                      FieldValue.arrayRemove([
                                                        memberId,
                                                      ]),
                                                });
                                          },
                                        ),
                                    ],
                                  )
                                  : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // Floating Action Button to add a new member (visible only for the leader)
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('channels')
                .doc(channelId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final channelData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String? leaderId = channelData['createdBy'] as String?;
          if (currentUserId == leaderId) {
            return FloatingActionButton(
              onPressed: () => _showAddUserDialog(context),
              child: const Icon(Icons.person_add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
