import 'package:flutter/material.dart';
import '../services/doctor_annie_copilot_service.dart';

class DoctorAnnieChatBubble extends StatefulWidget {
  const DoctorAnnieChatBubble({super.key});

  @override
  State<DoctorAnnieChatBubble> createState() => _DoctorAnnieChatBubbleState();
}

class _DoctorAnnieChatBubbleState extends State<DoctorAnnieChatBubble> with SingleTickerProviderStateMixin {
  final DoctorAnnieCopilotService _copilot = DoctorAnnieCopilotService();
  bool _isExpanded = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() => _isExpanded = !_isExpanded);
          if (_isExpanded) {
            _showChatDialog();
          }
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00BFA5),
                    Color(0xFF00E5FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00BFA5).withOpacity(0.3 + _pulseController.value * 0.3),
                    blurRadius: 20 + _pulseController.value * 10,
                    spreadRadius: 5 + _pulseController.value * 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: 30,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DoctorAnnieChatScreen(),
    );
  }
}

class DoctorAnnieChatScreen extends StatefulWidget {
  const DoctorAnnieChatScreen({super.key});

  @override
  State<DoctorAnnieChatScreen> createState() => _DoctorAnnieChatScreenState();
}

class _DoctorAnnieChatScreenState extends State<DoctorAnnieChatScreen> {
  final DoctorAnnieCopilotService _copilot = DoctorAnnieCopilotService();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final history = _copilot.getConversationHistory(limit: 10);
    for (final entry in history) {
      _messages.add(ChatMessage(
        text: entry['message'] as String,
        isUser: entry['role'] == 'user',
      ));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isLoading = true;
    });

    final response = await _copilot.sendMessage(text);

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Color(0xFF0A0E27),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
// Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Doctor Annie',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

// Messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message);
              },
            ),
          ),

// Loading indicator
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF00BFA5)),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Doctor Annie is thinking...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

// Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1A1E3A),
              border: Border(top: BorderSide(color: Color(0xFF00BFA5).withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask Doctor Annie...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFF0A0E27),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF00BFA5)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Color(0xFF00BFA5),
              child: Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? Color(0xFF00BFA5) : Color(0xFF1A1E3A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Color(0xFF1A1E3A),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}