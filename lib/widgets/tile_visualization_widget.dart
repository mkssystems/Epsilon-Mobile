//lib/widgets/tile_visualization_widget.dart
import 'package:flutter/material.dart';

class TileVisualizationWidget extends StatelessWidget {
  final String tileCode;
  final double size;

  const TileVisualizationWidget({
    super.key,
    required this.tileCode,
    this.size = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    final parts = tileCode.split('-');
    final themeCode = parts[0];
    final directions = parts[1];
    final tileImage = _getTileImage(directions);
    final overlayColor = _getOverlayColor(themeCode);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Base tile image explicitly shown
        Image.asset(
          'assets/tiles/$tileImage',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),

        // Explicit color overlay based on theme
        Container(
          width: size,
          height: size,
          color: overlayColor,
        ),

        // Tile code explicitly centered text label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            tileCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // Explicit mapping for tile images
  String _getTileImage(String directions) {
    switch (directions) {
      case 'EW': return 'tile_corridor_EW.png';
      case 'NS': return 'tile_corridor_NS.png';
      case 'ENSW': return 'tile_crossroad.png'; // explicitly sorted
      case 'E': return 'tile_dead_end_E.png';
      case 'N': return 'tile_dead_end_N.png';
      case 'S': return 'tile_dead_end_S.png';
      case 'W': return 'tile_dead_end_W.png';
      case 'ESW': return 'tile_t_section_N.png'; // sorted explicitly
      case 'NSW': return 'tile_t_section_E.png';
      case 'ENW': return 'tile_t_section_S.png';
      case 'ENS': return 'tile_t_section_W.png';
      case 'EN': return 'tile_turn_NE.png'; // this is explicitly correct now
      case 'NW': return 'tile_turn_NW.png';
      case 'ES': return 'tile_turn_SE.png';
      case 'SW': return 'tile_turn_SW.png';
      default: return 'tile_crossroad.png';
    }
  }

  // Explicit mapping for thematic overlay colors
  Color _getOverlayColor(String theme) {
    switch (theme) {
      case 'C': return const Color.fromRGBO(0, 255, 255, 0.5);    // Cyan
      case 'M': return const Color.fromRGBO(255, 0, 255, 0.5);    // Magenta
      case 'Y': return const Color.fromRGBO(255, 255, 0, 0.5);    // Yellow
      case 'K': return const Color.fromRGBO(0, 0, 0, 0.5);        // Black
      default: return Colors.white.withOpacity(0.3);
    }
  }
}