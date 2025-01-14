//
//  ViewController.swift
//  Notice App
//
//  Created by leeesangheee on 2021/09/26.
//

import Alamofire
import Kanna
import SnapKit
import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let tableView = UITableView()
    
    private var page: Int = 0
    private var noticeList: [Notice] = []
    private var isGettingData: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        configureNavigationBar()
        configureTableView()
        configureRefreshControl()
        
        getData()
        isGettingData = false
    }
    
    private func getData() {
        if !isGettingData { return }
        guard let url = URL(string: "https://cse.snu.ac.kr/department-notices?&keys=&page=\(page)") else { return }
        AF.request(url).responseString { response in
            guard let html = response.value else { return }
            do {
                let doc = try Kanna.HTML(html: html, encoding: .utf8)
                let docTexts = doc.css("td")
                if docTexts.count == 0 {
                    self.page -= 0
                    return
                }
                
                var textList: [String] = []
                var link: String = ""
                
                for docText in docTexts{
                    if let docLink = docText.css("a").first?["href"] {
                        link = "https://cse.snu.ac.kr\(docLink)"
                    }
                    guard let text = docText.text else { return }
                    let startIdx: String.Index = text.index(text.startIndex, offsetBy: 13)
                    let endIdx: String.Index = text.index(text.endIndex, offsetBy: -11)
                    let slicedText = String(text[startIdx...endIdx])
                    textList.append(slicedText)
                    if textList.count > 2 {
                        let notice = Notice(title: textList[0], time: textList[1], url: link)
                        self.noticeList.append(notice)
                        textList = []
                        link = ""
                    }
                }
                self.tableView.reloadData()
            } catch {
                print(error.localizedDescription)
            }
        }
        isGettingData = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewHeight = scrollView.frame.height
        let contentHeight = scrollView.contentSize.height
        let contentOffset = scrollView.contentOffset.y
        
        if contentHeight - contentOffset < scrollViewHeight {
            isGettingData = true
            page += 1
            getData()
        }
    }
    
    private func configureRefreshControl() {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        
        tableView.refreshControl?.tintColor = .mainBlue
    }
    
    @objc
    private func handleRefreshControl() {
        page = 0
        noticeList = []
        getData()
        tableView.reloadData()
        tableView.refreshControl?.endRefreshing()
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "컴퓨터공학부"
        let navigationBar = navigationController?.navigationBar
        
        if #available(iOS 13.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.backgroundColor = .mainBlue
            navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            
            navigationBar?.standardAppearance = navigationBarAppearance
            navigationBar?.compactAppearance = navigationBarAppearance
            navigationBar?.scrollEdgeAppearance = navigationBarAppearance
        } else {
            navigationBar?.barTintColor = .mainBlue
            navigationBar?.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBar?.tintColor = .white
        }
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NoticeTableViewCell.self, forCellReuseIdentifier: NoticeTableViewCell.identifier)
        tableView.separatorStyle = .none
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController(DetailViewController(noticeList[indexPath.row]), animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noticeList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoticeTableViewCell.identifier, for: indexPath) as? NoticeTableViewCell else { return UITableViewCell() }
        cell.notice = noticeList[indexPath.row]
        return cell
    }
}
