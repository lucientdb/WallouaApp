import 'package:flutter/material.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> { 
  Column buildColumnFrom(){
    bool seSouvenir=false;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: "Numero Client",
            icon: Icon(Icons.person_outline,color: Colors.blueAccent,)
          ),
        ),
        TextField(
          decoration: InputDecoration(
            labelText: "Mot de pass",
            icon: Icon(Icons.lock_open_outlined,color: Colors.blueAccent,),
            suffixIcon: Icon(Icons.remove_red_eye_outlined),
          ),
        ),
        SwitchListTile(
          value: seSouvenir,
         onChanged: (value) {
          setState(() {
            seSouvenir = value;
          });
         },
         controlAffinity: ListTileControlAffinity.leading,
         title: Text("Se souvenir de moi",),
         ),
         Container(
          width: double.infinity,
          height: 40,
          margin: EdgeInsets.only(top: 20),
          child: ElevatedButton(onPressed: () {},
           style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
           child: Text("Connexion",style: TextStyle(color: Colors.white,),),
           
           ),
           
         ),
         Container(
          margin: EdgeInsets.only(top: 10),
          alignment: Alignment.topRight,
          child: Text(
            "Mot de pass oublié ?",
            style: TextStyle(color: Colors.blueAccent),
          ),
         ),
      ],

    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:const BoxDecoration(
         gradient: LinearGradient( 
              begin: Alignment.topRight, 
              end: Alignment.bottomLeft, 
              colors: [ 
                Colors.red, 
                Colors.blue, 
              ], 
            ),   
         ),
         child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text("Wallou",style: TextStyle(color: Colors.white,)),
            centerTitle: true,
            leading: Icon(Icons.menu_sharp,color: Colors.white,),
            backgroundColor: Colors.blue,
          ),
          body: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(10),
              ),
              child: buildColumnFrom(),
            ),
          ),
         ),
    );
  }
}
