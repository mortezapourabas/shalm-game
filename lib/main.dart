import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'network/network_manager.dart';
import 'game_logic/game_controller.dart';
import 'screens/lobby_screen.dart';

void main() {
  runApp(const ShalmApp());
}

class ShalmApp extends StatelessWidget {
  const ShalmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkManager()),
        ChangeNotifierProxyProvider<NetworkManager, GameController>(
          create: (ctx) => GameController(
            network: Provider.of<NetworkManager>(ctx, listen: false),
          ),
          update: (ctx, network, prev) =>
              prev ?? GameController(network: network),
        ),
      ],
      child: MaterialApp(
        title: 'شلم',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Vazirmatn',
          useMaterial3: true,
        ),
        home: const LobbyScreen(),
      ),
    );
  }
}
