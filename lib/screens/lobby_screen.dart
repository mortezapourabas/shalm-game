import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_logic/game_controller.dart';
import '../models/game_state.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  bool _isLoading = false;
  String? _hostIp;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1B5E20),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildNameField(),
                  const SizedBox(height: 24),
                  Consumer<GameController>(
                    builder: (ctx, controller, _) {
                      if (controller.state.phase == GamePhase.lobby &&
                          controller.state.players.isNotEmpty) {
                        return _buildWaitingRoom(controller);
                      }
                      return _buildJoinOptions(controller);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text('🃏', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        const Text(
          'بازی شلم',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'بازی ورق ایرانی برای ۴ نفر',
          style: TextStyle(color: Colors.green[200], fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      textAlign: TextAlign.right,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'نام شما',
        labelStyle: TextStyle(color: Colors.green[200]),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.person, color: Colors.white54),
      ),
    );
  }

  Widget _buildJoinOptions(GameController controller) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _hostGame(controller),
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('ساخت بازی (هاست)', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ipController,
          textAlign: TextAlign.left,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'آدرس IP هاست',
            labelStyle: TextStyle(color: Colors.green[200]),
            hintText: 'مثال: 192.168.1.5',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.link, color: Colors.white54),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _joinGame(controller),
            icon: const Icon(Icons.login),
            label: const Text('پیوستن به بازی', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: Colors.white),
        ],
      ],
    );
  }

  Widget _buildWaitingRoom(GameController controller) {
    final players = controller.state.players;
    return Column(
      children: [
        if (_hostIp != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('آدرس IP برای اتصال دوستان:',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  _hostIp!,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بازیکنان (${players.length}/4)',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...players.map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    if (p.isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('هاست', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (players.length == 4 && controller.network.isHost)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.startGame();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('شروع بازی! 🎮',
                  style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          )
        else
          Text(
            players.length < 4
                ? 'منتظر ${4 - players.length} بازیکن دیگر...'
                : 'منتظر شروع توسط هاست...',
            style: TextStyle(color: Colors.green[200], fontSize: 16),
          ),
      ],
    );
  }

  Future<void> _hostGame(GameController controller) async {
    if (_nameController.text.trim().isEmpty) {
      _showError('لطفاً نام خود را وارد کنید');
      return;
    }
    setState(() => _isLoading = true);
    final ip = await controller.hostGame(_nameController.text.trim());
    setState(() { _isLoading = false; _hostIp = ip; });
    if (ip == null) _showError('خطا در راه‌اندازی سرور');
  }

  Future<void> _joinGame(GameController controller) async {
    if (_nameController.text.trim().isEmpty) {
      _showError('لطفاً نام خود را وارد کنید');
      return;
    }
    if (_ipController.text.trim().isEmpty) {
      _showError('لطفاً آدرس IP هاست را وارد کنید');
      return;
    }
    setState(() => _isLoading = true);
    final ok = await controller.joinGame(
      _ipController.text.trim(),
      _nameController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (!ok) _showError('اتصال به هاست ناموفق بود');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }
}
