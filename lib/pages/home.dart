import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff703eff),
      body: Container(
        margin: EdgeInsets.only(top: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          
        children:[
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Row(children: [
          Image.asset("images/wave.png", height: 40, width: 40, fit: BoxFit.cover,),
          
          SizedBox(width: 10.0,),
          Text("HELLO,", 
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight:  FontWeight.bold)),
          
          Text(" Moises", 
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight:  FontWeight.bold),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.only(right: 20.0),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child:Icon(Icons.person, color: Color(0xff703eff), size: 30.0 ),
          )
          ],
          ),
        ),

        SizedBox(height: 10.0,),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(" Bienvenido a:", 
          
          style: TextStyle(color: const Color.fromARGB(195, 255, 255, 255), fontSize: 24.0, fontWeight:  FontWeight.bold),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 20.0 ),
          child: Text("ChatUp", 
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 40.0, fontWeight:  FontWeight.bold),
          ),
        ),
        SizedBox(height: 30.0,),

        Expanded(
          child: Container(
            padding: EdgeInsets.only(left: 30.0, right: 20.0),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
            child: Column(children: [
              SizedBox(height: 30.0,), 
              Container(
                decoration: BoxDecoration(color: Color(0xFFececf8),borderRadius: BorderRadius.circular(10)
                ),
                child: TextField(

                  decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(Icons.search),
                  hintText: "Buscar Nombre..."),
                ),
              ),
              SizedBox(height: 20.0,),
              Material(
                elevation: 3.0,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                
                  children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.asset("images/boy.jpg", height: 70, width: 70, fit: BoxFit.cover,),
                  ),
                  SizedBox(width: 10.0,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10.0,),
                    Text("ElSarabambiche", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight:  FontWeight.w500),
                    ),
                
                    Text("Hola como estas mano :v? ", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: const Color.fromARGB(190, 0, 0, 0), fontSize: 18.0, fontWeight:  FontWeight.w500),
                    ),
                
                  ],
                  ),
                  Spacer(),
                    Text("02:00 PM", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black, fontSize: 18.0, fontWeight:  FontWeight.bold),
                    ),
                
                
                            ],),  ),
              )
            ],),
          ),
        )
      ]),),
    );
  }
}