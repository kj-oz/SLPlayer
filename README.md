SLPlayer
======================
SLPlayerは、[スリザーリンク][Wikipedia]、あるいはナンバーラインと呼ばれるペンシルパズルで遊ぶための、Objective-Cで書かれたiPad専用のアプリケーションです。

このソースからビルドされるアプリケーションは、Apple社のAppStoreで **スリザー** という名称で
無料で配信中です。  
　[https://itunes.apple.com/jp/app/suriza/id918911358?mt=8][AppStore]

画面イメージや使い方は、以下のページをご覧下さい。  
　[http://slitherlink-player.blogspot.jp][Blogger] 

###アプリケーションの特徴###

* 解き味を出来るだけ紙のパズルと同じになるようにしてあります。（線は点の間を指でなぞることで入力します。複数の点を連続して結ぶことも可能です。UNDO=元に戻す機能はありません。）
* 画面に納まりきれないような大きさのパズルでも遊ぶことが可能です。
* 自分で新しい問題を入力することが出来ます。その際に、1つ1つの数字を手で入力することも可能ですが、紙に印刷された問題をカメラで撮影して（あるいは既存の画像を選択して）自動認識させることも可能です。
 
###ソースコードの特徴###

* コメントは全て日本語です。メソッド定義等は、JavaDocの形式で記述しています。
* 画像認識部分のソースも全て自家製です。

###開発環境###

* 2014/09/18現在、Mac 0S X 10.9.4、Xcode 5.1.1

###使用ライブラリ###

[https://github.com/jivadevoe/UIAlertView-Blocks][UIAlertView-Blocks]

動作環境
-----
iOS 6.0以上、iPad専用

ライセンス
-----
 [MIT License][MIT]. の元で公開します。  

-----
Copyright &copy; 2014 Kj Oz  

[AppStore]: https://itunes.apple.com/jp/app/suriza/id918911358?mt=8
[Blogger]: http://slitherlink-player.blogspot.jp
[MIT]: http://www.opensource.org/licenses/mit-license.php
[Wikipedia]: http://ja.wikipedia.org/wiki/スリザーリンク
[UIAlertView-Blocks]: https://github.com/jivadevoe/UIAlertView-Blocks