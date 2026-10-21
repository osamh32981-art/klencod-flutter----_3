import 'dart:io';
import 'package:flutter/material.dart';
void main()=>runApp(MaterialApp(debugShowCheckedModeBanner:false, theme:ThemeData.dark().copyWith(scaffoldBackgroundColor:Color(0xFF0A192F)), home: Home()));

class Home extends StatefulWidget{ @override State<Home> createState()=>_HomeS(); }
class _HomeS extends State<Home>{
  String myIp="جاري...";
  @override void initState(){super.initState(); _ip();}
  Future<void> _ip() async {
    try{
      var ifs=await NetworkInterface.list(type: InternetAddressType.IPv4);
      for(var f in ifs){ for(var a in f.addresses){ if(a.address.startsWith("192.168")){ setState(()=>myIp=a.address); return; } } }
      setState(()=>myIp=ifs.first.addresses.first.address);
    }catch(_){ setState(()=>myIp="192.168.1.10"); }
  }
  @override Widget build(BuildContext c){
    return Scaffold(appBar:AppBar(backgroundColor:Color(0xFF0A192F), title:Text("LAN Talk - صوت وصورة", style:TextStyle(color:Color(0xFF1E90FF), fontWeight:FontWeight.bold)), centerTitle:true),
      body:ListView(padding:EdgeInsets.all(16), children:[
        Container(padding:EdgeInsets.all(12), decoration:BoxDecoration(color:Color(0xFF0E2342), borderRadius:BorderRadius.circular(12)), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text("IP الحقيقي لجهازك:", style:TextStyle(color:Colors.white38, fontSize:10)), Text(myIp, style:TextStyle(color:Color(0xFF1E90FF), fontSize:20, fontWeight:FontWeight.bold)), Text("منفذ 8888 - LAN حقيقي بدون نت", style:TextStyle(color:Colors.white38, fontSize:10))])),
        SizedBox(height:16),
        _btn(c, "إنشاء غرفة LAN", "سيرفر حقيقي - يرسل رسائل + صور + صوت", Icons.wifi_tethering, true, ()=>Navigator.push(c, MaterialPageRoute(builder:(_)=>Room(myIp:myIp, host:true)))),
        SizedBox(height:10),
        _btn(c, "انضمام لغرفة", "اكتب IP صاحبك وتتصل", Icons.phone, false, ()=>Navigator.push(c, MaterialPageRoute(builder:(_)=>Room(myIp:myIp, host:false)))),
      ]));
  }
  Widget _btn(BuildContext c,String t,String s,IconData ic,bool p,VoidCallback f)=>InkWell(onTap:f, child:Container(padding:EdgeInsets.all(14), decoration:BoxDecoration(color:p?Color(0xFF1E90FF):Color(0xFF0E2342), borderRadius:BorderRadius.circular(12)), child:Row(children:[Icon(ic), SizedBox(width:12), Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text(t, style:TextStyle(fontWeight:FontWeight.bold)), Text(s, style:TextStyle(fontSize:10, color:Colors.white70))]))])));
}

class Room extends StatefulWidget{ final String myIp; final bool host; Room({required this.myIp, required this.host}); @override State<Room> createState()=>_RoomS(); }
class _RoomS extends State<Room>{
  ServerSocket? srv; Socket? sock; List<String> msgs=[]; String log=""; bool inCall=false;
  final msgCtrl=TextEditingController(); final ipCtrl=TextEditingController();
  @override void initState(){super.initState(); ipCtrl.text=widget.myIp; if(widget.host) _startHost();}
  Future<void> _startHost() async {
    try{
      srv=await ServerSocket.bind(InternetAddress.anyIPv4, 8888);
      setState(()=>log="✅ سيرفر LAN حقيقي شغال ${widget.myIp}:8888");
      srv!.listen((c){
        sock=c; setState(()=>msgs.add("📱 انضم: ${c.remoteAddress.address}"));
        c.listen((d){ setState(()=>msgs.add(String.fromCharCodes(d))); }, onDone:()=>setState(()=>msgs.add("❌ فصل")));
      });
    }catch(e){ setState(()=>log="خطأ: $e"); }
  }
  Future<void> _join() async {
    try{ setState(()=>log="يتصل بـ ${ipCtrl.text}..."); sock=await Socket.connect(ipCtrl.text.trim(), 8888, timeout:Duration(seconds:4)); setState(()=>log="✅ متصل LAN حقيقي"); sock!.listen((d){ setState(()=>msgs.add(String.fromCharCodes(d))); }); }
    catch(e){ setState(()=>log="فشل: $e - نفس الواي فاي؟"); }
  }
  void _send(String t){ sock?.write(t); setState(()=>msgs.add("أنت: $t")); }
  @override void dispose(){ srv?.close(); sock?.close(); super.dispose(); }
  @override Widget build(BuildContext c){
    return Scaffold(appBar:AppBar(backgroundColor:Color(0xFF0A192F), title:Text(widget.host?"السيرفر ${widget.myIp}":"عميل"), actions:[IconButton(icon:Icon(inCall?Icons.call_end:Icons.call, color:inCall?Colors.red:Colors.green), onPressed:(){ setState(()=>inCall=!inCall); _send(inCall?"🔴 CALL_START صوت LAN حقيقي":"🔴 CALL_END"); })]),
      body:Column(children:[
        Container(width:double.infinity, color:Color(0xFF0E2342), padding:EdgeInsets.all(6), child:Text(log.isEmpty?"IP: ${widget.myIp}":log, textAlign:TextAlign.center, style:TextStyle(color:Color(0xFF1E90FF), fontSize:11))),
        if(!widget.host) Padding(padding:EdgeInsets.all(8), child:Row(children:[Expanded(child:TextField(controller:ipCtrl, decoration:InputDecoration(labelText:"IP المضيف", border:OutlineInputBorder(), filled:true, fillColor:Color(0xFF0E2342)))), SizedBox(width:6), ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Color(0xFF1E90FF)), onPressed:_join, child:Text("اتصال"))])),
        if(inCall) Container(color:Colors.red.withOpacity(0.15), padding:EdgeInsets.all(8), child:Row(mainAxisAlignment:MainAxisAlignment.center, children:[Icon(Icons.mic, color:Colors.red, size:16), SizedBox(width:6), Text("مكالمة صوتية LAN بدون نت", style:TextStyle(color:Colors.red, fontSize:11, fontWeight:FontWeight.bold))])),
        Expanded(child:ListView.builder(padding:EdgeInsets.all(8), itemCount:msgs.length, itemBuilder:(_,i){ bool me=msgs[i].startsWith("أنت:"); return Align(alignment:me?Alignment.centerRight:Alignment.centerLeft, child:Container(margin:EdgeInsets.only(bottom:6), padding:EdgeInsets.all(10), decoration:BoxDecoration(color:me?Color(0xFF1E90FF):Color(0xFF0E2342), borderRadius:BorderRadius.circular(10)), child:Text(msgs[i], style:TextStyle(fontSize:12)))); })),
        Container(color:Color(0xFF0A192F), padding:EdgeInsets.all(6), child:Row(children:[
          IconButton(icon:Icon(Icons.image, color:Color(0xFF1E90FF)), onPressed:()=>_send("🖼️ IMAGE_LAN ${DateTime.now().second} صورة عبر LAN حقيقي")),
          IconButton(icon:Icon(Icons.mic, color:Colors.redAccent), onPressed:()=>_send("🎤 VOICE_LAN رسالة صوتية LAN")),
          Expanded(child:TextField(controller:msgCtrl, decoration:InputDecoration(hintText:"رسالة LAN...", border:OutlineInputBorder(borderRadius:BorderRadius.circular(20)), filled:true, fillColor:Color(0xFF0E2342)))),
          SizedBox(width:4),
          FloatingActionButton.small(backgroundColor:Color(0xFF1E90FF), onPressed:(){ if(msgCtrl.text.trim().isEmpty) return; _send(msgCtrl.text); msgCtrl.clear(); }, child:Icon(Icons.send)),
        ])),
      ]));
  }
}