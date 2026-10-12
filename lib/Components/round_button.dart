import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  final String title;
  final VoidCallback onPress;
  RoundButton({required this.title,required this.onPress});
  @override
  Widget build(BuildContext context) {
    return Material (
        borderRadius:BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: MaterialButton(
          child: Text(title,style: TextStyle(color: Colors.white),),
          color: const Color(0xFFEB740C),
          height: 50,
          minWidth: double.infinity,
          onPressed: onPress,
        )
    );
  }
}