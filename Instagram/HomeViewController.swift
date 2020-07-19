//
//  HomeViewController.swift
//  Instagram
//
//  Created by 山岡巧 on 2020/06/08.
//  Copyright © 2020 takumi.yamaoka. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // 投稿データを格納する配列
    var postArray: [PostData] = []
    
    
    // Firestoreのリスナー
    var listener: ListenerRegistration!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // カスタムセルを登録する
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        
        if Auth.auth().currentUser != nil {
            // ログイン済み
            if listener == nil {
                // listener未登録なら、登録してスナップショットを受信する
                let postsRef = Firestore.firestore().collection(Const.PostPath).order(by: "date", descending: true)
                listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                    if let error = error {
                        print("DEBUG_PRINT: snapshotの取得が失敗しました。\(error)")
                        return
                    }
                    // 取得したdocumentをもとにPostDataを作成し、postArrayの配列にする。
                    self.postArray = querySnapshot!.documents.map { document in
                        print("DEBUG_PRINT: document取得\(document.documentID)")
                        let postData = PostData(document: document)
                        return postData
                    }
                    // TableViewの表示を更新する
                    self.tableView.reloadData()
                }
            }
        } else {
            // ログイン未（またはログインアウト済）
            if listener != nil {
                // listener登録済なら削除してpostArrayをクリアする
                listener.remove()
                listener = nil
                postArray = []
                tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell
        cell.setPostData(postArray[indexPath.row])
        
        // セル内のボタンのアクションをソースコードで設定する
        cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
        cell.comentButton.addTarget(self, action: #selector(commentsButton(_:forEvent:)), for: .touchUpInside)
        
        return cell
    }
    
    // セル内のボタンがタップされた時に呼ばれるメソッド
    @objc func handleButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")
        
        // タップされたセルのインデックスをもとめる
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        // likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            // 更新データを作成する
            var updateValue: FieldValue
            if postData.isLiked {
                // すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue  = FieldValue.arrayRemove([myid])
            } else {
                // 今回新たにいいねを押した場合は、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([myid])
            }
            // likesに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            postRef.updateData(["likes": updateValue])
        }
    }
    
    
    
    @objc func commentsButton(_ sender: UIButton, forEvent event: UIEvent) {
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        print(postData.id)
        
        let ac = UIAlertController(title: "コメント", message: "", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: {[weak ac] (action) -> Void in
            print("DEBUG_PRINT: OKボタンが押されました")
            guard let textFields = ac?.textFields else {
                return
            }
            guard !textFields.isEmpty else {
                return
            }
            
            // テキストを取り出して値をFirebaseに保存する
            for text in textFields {
                let username = Auth.auth().currentUser!.displayName!
                let commentText = text.text!
                let comment = "\(username) : \(commentText)"
                
                let updateValue = FieldValue.arrayUnion([comment])
                
                let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
                postRef.updateData(["comment": updateValue])

                print("DEBUG_PRINT: テキストフィールドの値は\(text.text)")
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        //textfiled1の追加
        ac.addTextField(configurationHandler: {(text:UITextField!) -> Void in
        
            text.text = text.text
            print(text.text)
            
        })

//        if commentsButton.addTextField {
//            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
//            postRef.updateData(["comments": updateValue])
//        }

        ac.addAction(ok)
        ac.addAction(cancel)

        present(ac, animated: true, completion: nil)


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    }
    
}
