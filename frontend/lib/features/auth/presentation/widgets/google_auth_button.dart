import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    required this.action,
    required this.onPressed,
    super.key,
  });

  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Atau $action Dengan',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            height: 16 / 11,
          ),
        ),
        const SizedBox(height: 9),
        Semantics(
          button: true,
          label: '$action dengan Google',
          child: Material(
            color: Colors.white,
            elevation: 4,
            shadowColor: const Color(0x66000000),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: const SizedBox.square(
                dimension: 67,
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.google,
                    color: Color(0xFF4285F4),
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
