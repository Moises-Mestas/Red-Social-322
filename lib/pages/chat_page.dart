import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff703eff),
      body: Container(
        margin: EdgeInsets.only(top: 40.0),
        child: Column(children: [
    Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: Row(children: [
        GestureDetector(
          onTap: (){
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios_new_rounded,color: Colors.white,)),
        SizedBox(width: MediaQuery.of(context).size.width/5,),
        Text("ElSarabambiche", 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 26.0, fontWeight:  FontWeight.bold)),
                
      ],),
    ),
      SizedBox(height: 20.0,),
    Expanded(
          child: Container(
          padding: EdgeInsets.only(left:10.0),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), ),
            
        child: Column(children: [
          SizedBox(height: 50.0,),
          Row(children: [
            Container(
              padding: EdgeInsets.all(13),
              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30), bottomRight: Radius.circular(30)  )),
        child: Text("Hola como estas mano :v?", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight:  FontWeight.bold)
                    ),

                    )
          ],),

        SizedBox(height: 20.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
            Container(
              margin: EdgeInsets.only(right: 20.0),
              padding: EdgeInsets.all(13),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30), bottomLeft: Radius.circular(30)  )),
              child: Text(
                    "ESTOY bien mano :D", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight:  FontWeight.bold)
                    ),

                    )
          ],),
          SizedBox(
            height: MediaQuery.of(context).size.height/1.6,
          ),
          Container(
            child: Row(children: [
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(color: Color(0xff703eff),borderRadius: BorderRadius.circular(60)
                ),
                child: Icon(
                  Icons.mic,size: 35.0,
                   color: Colors.white, ),
              ),
              SizedBox(width: 10.0,),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: 10.0),
                  decoration: BoxDecoration(color: Color(0xFFececf8), borderRadius: BorderRadius.circular(10)),
                  child: TextField(

                    decoration: InputDecoration(border: InputBorder.none, 
                    hintText: "Escribir un mensaje...", suffixIcon: Icon(Icons.attach_file)),
                  )),
              ),
            SizedBox(width: 10.0,),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xff703eff),
                
                  borderRadius: BorderRadius.circular(60)
                ),
                child: Icon(
                  Icons.send,
                  size: 30.0,
                   color: Colors.white, ),
              ),
                  SizedBox(width: 10.0,),
            ],),
          )
        ],) ,))
      ],
      ),),
    );
  }
}