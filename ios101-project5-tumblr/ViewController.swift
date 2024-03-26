//
//  ViewController.swift
//  ios101-project5-tumbler
//

import UIKit
import Nuke

class ViewController: UIViewController, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("🍏 cellForRowAt called for row: \(indexPath.row)")

            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell

            Nuke.cancelRequest(for: cell.postImageView)

            let post = posts[indexPath.row]

            if let photo = post.photos.first {
                let url = photo.originalSize.url
                Nuke.loadImage(with: url, into: cell.postImageView)
            }

            cell.postLabel.text = post.summary

            return cell
        }
    
    
    @IBOutlet weak var tableView: UITableView!
    private var posts: [Post] = []
    let refreshControl = UIRefreshControl()
    deinit {
        tableView.visibleCells.compactMap { ($0 as? PostCell)?.postImageView }.forEach {
            Nuke.cancelRequest(for: $0)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
            tableView.dataSource = self
            fetchPosts { _ in }
            tableView.refreshControl = refreshControl
            refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        }

    @objc func refreshData(_ sender: UIRefreshControl) {
        fetchPosts { [weak self] success in
            guard success else {
                sender.endRefreshing()
                return
            }
            
            self?.tableView.reloadData()
            print("✅ We got \(self?.posts.count ?? 0) posts!")
            for post in self?.posts ?? [] {
                print("🍏 Summary: \(post.summary)")
            }
            sender.endRefreshing()
        }
    }
        func fetchPosts(completion: @escaping (Bool) -> Void) {
            let url = URL(string: "https://api.tumblr.com/v2/blog/rosannapansino/posts/photo?api_key=1zT8CiXGXFcQDyMFG7RtcfGLwTdDjFUJnZzKJaWTmgyK4lKGYk&offset=500")!
            let session = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                print("❌ Response error: \(String(describing: response))")
                completion(false)
                return
            }
            
            guard let data = data else {
                print("❌ Data is NIL")
                completion(false)
                return
            }
            
            do {
                let blog = try JSONDecoder().decode(Blog.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    let posts = blog.response.posts
                    self?.posts = posts
                    self?.tableView.reloadData()
                    print("✅ We got \(posts.count) posts!")
                    for post in posts {
                        print("🍏 Summary: \(post.summary)")
                    }
                    completion(true)
                }
            } catch {
                print("❌ Error decoding JSON: \(error.localizedDescription)")
                completion(false)
            }
        }
        
        session.resume()
    }
}
