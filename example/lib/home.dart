import 'package:example/const.dart';
import 'package:flutter/material.dart';
import 'package:wukongimfluttersdk/entity/conversation.dart';
import 'package:wukongimfluttersdk/type/const.dart';
import 'package:wukongimfluttersdk/wkim.dart';

import 'chat.dart';
import 'contestation.dart';
import 'input_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.redAccent,
      ),
      home: const ListViewShowData(),
    );
  }
}

class ListViewShowData extends StatefulWidget {
  const ListViewShowData({super.key});

  @override
  State<StatefulWidget> createState() {
    return ListViewShowDataState();
  }
}

class ListViewShowDataState extends State<ListViewShowData> {
  List<UIConversation> msgList = [];
  @override
  void initState() {
    super.initState();
    _getDataList();
    _initListener();
  }

  var _connectionStatusStr = '';
  _initListener() {
    WKIM.shared.connectionManager.addOnConnectionStatus('home',
        (status, reason) {
      if (status == WKConnectStatus.connecting) {
        _connectionStatusStr = '连接中...';
      } else if (status == WKConnectStatus.success) {
        _connectionStatusStr = '最近会话';
      } else if (status == WKConnectStatus.noNetwork) {
        _connectionStatusStr = '网络异常';
      } else if (status == WKConnectStatus.syncMsg) {
        _connectionStatusStr = '同步消息中...';
      }
      setState(() {});
    });
    WKIM.shared.conversationManager.addOnRefreshMsgListener('chat_conversation',
        (msg, isEnd) {
      bool isAdd = true;
      for (var i = 0; i < msgList.length; i++) {
        if (msgList[i].msg.channelID == msg.channelID &&
            msgList[i].msg.channelType == msg.channelType) {
          msgList[i].msg = msg;
          msgList[i].lastContent = '';
          isAdd = false;
          break;
        }
      }
      if (isAdd) {
        msgList.add(UIConversation(msg));
      }
      if (isEnd) {
        setState(() {});
      }
    });
  }

  void _getDataList() {
    Future<List<WKUIConversationMsg>> list =
        WKIM.shared.conversationManager.getAll();
    list.then((result) {
      for (var i = 0; i < result.length; i++) {
        msgList.add(UIConversation(result[i]));
      }

      setState(() {});
    });
  }

  String getShowContent(UIConversation uiConversation) {
    if (uiConversation.lastContent == '') {
      uiConversation.msg.getWkMsg().then((value) {
        if (value != null && value.messageContent != null) {
          uiConversation.lastContent = value.messageContent!.displayText();
          setState(() {});
        }
      });
      return '';
    }
    return uiConversation.lastContent;
  }

  Widget _buildRow(UIConversation uiMsg) {
    return Container(
        margin: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  color: Colors.blue),
              width: 50,
              alignment: Alignment.center,
              height: 50,
              margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Text(
                CommonUtils.getAvatar(uiMsg.msg.channelID),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        uiMsg.msg.channelID,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 18),
                        maxLines: 1,
                      ),
                      Expanded(
                        child: Text(
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                          CommonUtils.formatDateTime(
                              uiMsg.msg.lastMsgTimestamp),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        getShowContent(uiMsg),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        maxLines: 1,
                      ),
                      Expanded(
                        child: Text(
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          uiMsg.getUnreadCount(),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  )
                ]))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connectionStatusStr),
      ),
      body: ListView.builder(
          shrinkWrap: true,
          itemCount: msgList.length,
          itemBuilder: (context, pos) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(),
                    settings: RouteSettings(
                      arguments: ChatChannel(
                        msgList[pos].msg.channelID,
                        msgList[pos].msg.channelType,
                      ),
                    ),
                  ),
                );
              },
              child: _buildRow(msgList[pos]),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDialog(context);
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => InputDialog(
        title: const Text("创建新的聊天"),
        back: (channelID, channelType) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(),
              settings: RouteSettings(
                arguments: ChatChannel(
                  channelID,
                  channelType,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
