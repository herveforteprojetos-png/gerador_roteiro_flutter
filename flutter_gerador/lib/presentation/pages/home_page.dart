import 'package:flutter/material.dart';
import 'package:flutter_gerador/presentation/widgets/layout/sidebar_panel.dart';
import 'package:flutter_gerador/presentation/widgets/layout/main_content_area.dart';
import 'package:flutter_gerador/core/constants/app_colors.dart';
import 'package:flutter_gerador/core/constants/app_sizes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Coluna Esquerda - Painel de Configuração
          Container(
            width: AppSizes.sidebarWidth,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              border: Border(
                right: BorderSide(color: AppColors.fireOrange),
              ),
            ),
            child: const SidebarPanel(),
          ),
          // Coluna Direita - Área Principal
          const Expanded(
            child: MainContentArea(),
          ),
        ],
      ),
    );
  }
}
