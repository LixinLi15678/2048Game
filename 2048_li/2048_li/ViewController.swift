//
//  ViewController.swift
//  2048_li
//
//  Created by 李利鑫 on 1/16/25.
//

import UIKit

// 一个 tile 数据结构
struct Tile: Codable, Equatable {
    var id: Int
    var value: Int
}

// 用于存档/回档时保存的数据
struct GameState: Codable {
    var grid: [[Tile?]]
    var score: Int
    var tileIdCounter: Int
    var mode: Int
    var bestScore: Int   // 新增最高分
}

class ViewController: UIViewController {
    let GRID_SIZE = 4
    let MAX_HISTORY = 10
    
    var grid: [[Tile?]] = []
    var score = 0
    var mode = 0
    var tileIdCounter = 0
    var history: [GameState] = []
    
    // 新增：最高分
    var bestScore = 0

    // 顶部 UI
    let titleLabel = UILabel()
    
    // 分数容器
    let scoreContainer = UIView()
    let scoreTitleLabel = UILabel()
    let scoreValueLabel = UILabel()
    
    // 最高分容器
    let bestScoreContainer = UIView()
    let bestScoreTitleLabel = UILabel()
    let bestScoreValueLabel = UILabel()
    
    let undoButton = UIButton(type: .system)
    let restartButton = UIButton(type: .system)
    let toggleModeButton = UIButton(type: .system)
    
    // 棋盘
    let boardView = UIView()
    var tileViews: [Int: UIView] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 背景
        view.backgroundColor = UIColor(red: 0xfa/255.0, green: 0xf8/255.0, blue: 0xef/255.0, alpha: 1)

        // 读取存档
        onLoad()
        
        setupUI()
        initGame()
        setupGestures()
    }
    
    func initGame() {
        // 若 grid 为空则新开，否则保留现有
        if grid.isEmpty {
            grid = Array(repeating: Array(repeating: nil, count: GRID_SIZE), count: GRID_SIZE)
            spawnTile()
            spawnTile()
        }
        updateUI(animated: false)
        updateToggleButtonTitle()
        
        // 防止启动时UI未渲染
        DispatchQueue.main.async {
            self.updateUI(animated: false)
        }
    }
    
    // MARK: - UI 布局
    func setupUI() {
        // 顶部条
        let topBar = UIView()
        view.addSubview(topBar)
        topBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            topBar.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // 标题“2048”
        titleLabel.text = "2048"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 48)
        titleLabel.textColor = UIColor(red: 0x77/255.0, green: 0x6e/255.0, blue: 0x65/255.0, alpha: 1)
        
        // === 给标题加点击手势，点击后弹窗“专为lxn设计” ===
        titleLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTitleTap))
        titleLabel.addGestureRecognizer(tapGesture)
        
        // 分数容器
        scoreContainer.backgroundColor = UIColor(red: 0xbb/255.0, green: 0xad/255.0, blue: 0xa0/255.0, alpha: 1)
        scoreContainer.layer.cornerRadius = 3
        scoreContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreContainer.widthAnchor.constraint(equalToConstant: 80),
            scoreContainer.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        scoreTitleLabel.text = "分数"
        scoreTitleLabel.font = UIFont.systemFont(ofSize: 14)
        scoreTitleLabel.textColor = .white
        scoreTitleLabel.textAlignment = .center
        
        scoreValueLabel.text = "\(score)"
        scoreValueLabel.font = UIFont.boldSystemFont(ofSize: 18)
        scoreValueLabel.textColor = .white
        scoreValueLabel.textAlignment = .center
        
        let scoreStack = UIStackView(arrangedSubviews: [scoreTitleLabel, scoreValueLabel])
        scoreStack.axis = .vertical
        scoreStack.alignment = .center
        scoreStack.distribution = .fillEqually
        scoreContainer.addSubview(scoreStack)
        scoreStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreStack.centerXAnchor.constraint(equalTo: scoreContainer.centerXAnchor),
            scoreStack.centerYAnchor.constraint(equalTo: scoreContainer.centerYAnchor),
            scoreStack.widthAnchor.constraint(equalTo: scoreContainer.widthAnchor),
            scoreStack.heightAnchor.constraint(equalTo: scoreContainer.heightAnchor)
        ])
        
        // === 最高分容器 ===
        bestScoreContainer.backgroundColor = UIColor(red: 0xbb/255.0, green: 0xad/255.0, blue: 0xa0/255.0, alpha: 1)
        bestScoreContainer.layer.cornerRadius = 3
        bestScoreContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bestScoreContainer.widthAnchor.constraint(equalToConstant: 80),
            bestScoreContainer.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        bestScoreTitleLabel.text = "最高分"
        bestScoreTitleLabel.font = UIFont.systemFont(ofSize: 14)
        bestScoreTitleLabel.textColor = .white
        bestScoreTitleLabel.textAlignment = .center
        
        bestScoreValueLabel.text = "\(bestScore)"
        bestScoreValueLabel.font = UIFont.boldSystemFont(ofSize: 18)
        bestScoreValueLabel.textColor = .white
        bestScoreValueLabel.textAlignment = .center
        
        let bestScoreStack = UIStackView(arrangedSubviews: [bestScoreTitleLabel, bestScoreValueLabel])
        bestScoreStack.axis = .vertical
        bestScoreStack.alignment = .center
        bestScoreStack.distribution = .fillEqually
        bestScoreContainer.addSubview(bestScoreStack)
        bestScoreStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bestScoreStack.centerXAnchor.constraint(equalTo: bestScoreContainer.centerXAnchor),
            bestScoreStack.centerYAnchor.constraint(equalTo: bestScoreContainer.centerYAnchor),
            bestScoreStack.widthAnchor.constraint(equalTo: bestScoreContainer.widthAnchor),
            bestScoreStack.heightAnchor.constraint(equalTo: bestScoreContainer.heightAnchor)
        ])
        
        // 把 “最高分容器” 和 “分数容器” 纵向堆叠，让最高分在上
        let scorePairStack = UIStackView(arrangedSubviews: [
            bestScoreContainer,
            scoreContainer
        ])
        scorePairStack.axis = .vertical
        scorePairStack.alignment = .center
        scorePairStack.spacing = 8
        
        // 撤销 / 重新开始 / 模式
        styleButton(undoButton, title: "撤销")
        undoButton.addTarget(self, action: #selector(onUndo), for: .touchUpInside)
        
        styleButton(restartButton, title: "重新开始")
        restartButton.addTarget(self, action: #selector(onRestart), for: .touchUpInside)
        
        styleButton(toggleModeButton, title: "模式: 正常")
        toggleModeButton.addTarget(self, action: #selector(onToggleMode), for: .touchUpInside)
        
        let topButtonsStack = UIStackView(arrangedSubviews: [undoButton, restartButton])
        topButtonsStack.axis = .horizontal
        topButtonsStack.alignment = .center
        topButtonsStack.spacing = 10
        
        let rightStack = UIStackView(arrangedSubviews: [topButtonsStack, toggleModeButton])
        rightStack.axis = .vertical
        rightStack.alignment = .leading
        rightStack.spacing = 10
        
        // 最外层： [titleLabel, scorePairStack, rightStack]
        let rowStack = UIStackView(arrangedSubviews: [titleLabel, scorePairStack, rightStack])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.distribution = .equalSpacing
        rowStack.spacing = 10
        
        topBar.addSubview(rowStack)
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            rowStack.topAnchor.constraint(equalTo: topBar.topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: topBar.bottomAnchor)
        ])
        
        // 棋盘
        view.addSubview(boardView)
        boardView.translatesAutoresizingMaskIntoConstraints = false
        let size = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 40
        NSLayoutConstraint.activate([
            boardView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 20),
            boardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            boardView.widthAnchor.constraint(equalToConstant: size),
            boardView.heightAnchor.constraint(equalToConstant: size)
        ])
        boardView.backgroundColor = UIColor(red: 0xbb/255.0, green: 0xad/255.0, blue: 0xa0/255.0, alpha: 1)
        boardView.layer.cornerRadius = 10
        
        let cellSize = (size - 10*5) / 4
        for i in 0..<GRID_SIZE {
            for j in 0..<GRID_SIZE {
                let bgCell = UIView()
                bgCell.backgroundColor = UIColor(red: 0xcd/255.0, green: 0xc1/255.0, blue: 0xb4/255.0, alpha: 1)
                bgCell.layer.cornerRadius = 3
                let x = CGFloat(j) * (cellSize + 10) + 10
                let y = CGFloat(i) * (cellSize + 10) + 10
                bgCell.frame = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                boardView.addSubview(bgCell)
            }
        }
    }
    
    // 点击标题弹窗
    @objc func onTitleTap() {
        let alert = UIAlertController(title: "专为 lxn 设计", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func styleButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(red: 0x8f/255.0, green: 0x7a/255.0, blue: 0x66/255.0, alpha: 1)
        button.setTitleColor(UIColor(red: 0xf9/255.0, green: 0xf6/255.0, blue: 0xf2/255.0, alpha: 1), for: .normal)
        button.layer.cornerRadius = 5
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
    
    // MARK: - 手势
    func setupGestures() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.left, .right, .up, .down]
        for dir in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
            swipe.direction = dir
            view.addGestureRecognizer(swipe)
        }
    }
    
    @objc func onSwipe(_ gesture: UISwipeGestureRecognizer) {
        pushHistory()
        let oldScore = score
        var moved = false
        var scoreIncrement = 0
        
        switch gesture.direction {
        case .left:
            (moved, scoreIncrement) = moveLeft()
        case .right:
            (moved, scoreIncrement) = moveRight()
        case .up:
            (moved, scoreIncrement) = moveUp()
        case .down:
            (moved, scoreIncrement) = moveDown()
        default:
            break
        }
        
        if moved {
            score += scoreIncrement
            // 若当前分数超过最高分，则更新
            if score > bestScore {
                bestScore = score
            }
            
            spawnTile()
            updateUI(animated: true)
            showScoreChange(diff: score - oldScore)
            onSave()
            
            if isGameOver() {
                showGameOverAlert()
            }
        } else {
            _ = history.popLast()
        }
    }
    
    // MARK: - 核心逻辑
    func pushHistory() {
        let currentState = GameState(
            grid: grid,
            score: score,
            tileIdCounter: tileIdCounter,
            mode: mode,
            bestScore: bestScore
        )
        history.append(currentState)
        if history.count > MAX_HISTORY {
            history.removeFirst()
        }
    }
    
    @objc func onUndo() {
        undo()
    }
    
    func undo() {
        guard let last = history.popLast() else { return }
        let oldScore = score
        grid = last.grid
        score = last.score
        tileIdCounter = last.tileIdCounter
        mode = last.mode
        bestScore = last.bestScore
        
        updateUI(animated: false)
        showScoreChange(diff: score - oldScore)
        updateToggleButtonTitle()
        onSave()
    }
    
    @objc func onRestart() {
        pushHistory()
        let oldScore = score
        
        grid = Array(repeating: Array(repeating: nil, count: GRID_SIZE), count: GRID_SIZE)
        score = 0
        tileIdCounter = 0
        
        spawnTile()
        spawnTile()
        
        updateUI(animated: false)
        showScoreChange(diff: score - oldScore)
        onSave()
    }
    
    @discardableResult
    func spawnTile() -> Bool {
        let emptyCells = grid.indices.flatMap { i in
            grid[i].indices.compactMap { j in
                grid[i][j] == nil ? (i, j) : nil
            }
        }
        if emptyCells.isEmpty { return false }
        
        let (x, y) = emptyCells.randomElement()!
        
        let val: Int
        switch mode {
        case 0:
            // 正常: 90% 出2, 10% 出4
            val = Double.random(in: 0..<1) < 0.9 ? 2 : 4
        case 1:
            // 只出2
            val = 2
        case 2:
            // 只出4
            val = 4
        default:
            // 作弊: 512
            val = 512
        }
        
        let t = Tile(id: tileIdCounter, value: val)
        tileIdCounter += 1
        grid[x][y] = t
        return true
    }
    
    func moveLine(_ line: [Tile?]) -> ([Tile?], Bool, Int) {
        let nonEmptyTiles = line.compactMap { $0 }
        var arr = nonEmptyTiles
        var moved = false
        var scoreInc = 0
        
        var j = 0
        while j < arr.count - 1 {
            if arr[j].value == arr[j+1].value {
                let newVal = arr[j].value * 2
                arr[j] = Tile(id: tileIdCounter, value: newVal)
                tileIdCounter += 1
                scoreInc += newVal
                arr.remove(at: j+1)
            }
            j += 1
        }
        
        var newLine = arr.map { Optional($0) }
        while newLine.count < GRID_SIZE {
            newLine.append(nil)
        }
        
        moved = (newLine.map { $0?.id } != line.map { $0?.id })
        return (newLine, moved, scoreInc)
    }
    
    func moveLeft() -> (Bool, Int) {
        var moved = false
        var totalScoreInc = 0
        for i in 0..<GRID_SIZE {
            let line = grid[i]
            let (newLine, lineMoved, scoreInc) = moveLine(line)
            grid[i] = newLine
            if lineMoved {
                moved = true
                totalScoreInc += scoreInc
            }
        }
        return (moved, totalScoreInc)
    }
    
    func moveRight() -> (Bool, Int) {
        reverseRows()
        let (moved, scoreInc) = moveLeft()
        reverseRows()
        return (moved, scoreInc)
    }
    
    func moveUp() -> (Bool, Int) {
        transpose()
        let (moved, scoreInc) = moveLeft()
        transpose()
        return (moved, scoreInc)
    }
    
    func moveDown() -> (Bool, Int) {
        transpose()
        reverseRows()
        let (moved, scoreInc) = moveLeft()
        reverseRows()
        transpose()
        return (moved, scoreInc)
    }
    
    func reverseRows() {
        for i in 0..<GRID_SIZE {
            grid[i].reverse()
        }
    }
    
    func transpose() {
        var newGrid: [[Tile?]] = Array(
            repeating: Array(repeating: nil, count: GRID_SIZE),
            count: GRID_SIZE
        )
        for i in 0..<GRID_SIZE {
            for j in 0..<GRID_SIZE {
                newGrid[i][j] = grid[j][i]
            }
        }
        grid = newGrid
    }
    
    func isGameOver() -> Bool {
        // 有空格则未结束
        for i in 0..<GRID_SIZE {
            for j in 0..<GRID_SIZE {
                if grid[i][j] == nil {
                    return false
                }
            }
        }
        // 判断还能否合并
        for i in 0..<GRID_SIZE {
            for j in 0..<GRID_SIZE {
                if j < GRID_SIZE - 1,
                   let a = grid[i][j],
                   let b = grid[i][j+1],
                   a.value == b.value {
                    return false
                }
                if i < GRID_SIZE - 1,
                   let c = grid[i][j],
                   let d = grid[i+1][j],
                   c.value == d.value {
                    return false
                }
            }
        }
        return true
    }
    
    // 当没有可移动步数时，弹出「新游戏 / 撤销」
    func showGameOverAlert() {
        let alert = UIAlertController(title: "游戏结束", message: "没有可移动的步数", preferredStyle: .alert)
        
        // 新游戏
        let restartAction = UIAlertAction(title: "新游戏", style: .default) { _ in
            self.onRestart()
        }
        // 撤销
        let undoAction = UIAlertAction(title: "撤销", style: .default) { _ in
            self.onUndo()
        }
        
        alert.addAction(restartAction)
        alert.addAction(undoAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UI 刷新
    func updateUI(animated: Bool) {
        scoreValueLabel.text = "\(score)"
        // 如果当前分数超过最高分，则更新
        if score > bestScore {
            bestScore = score
        }
        bestScoreValueLabel.text = "\(bestScore)"
        
        let size = boardView.bounds.width
        let cellSize = (size - 10*5) / 4
        var usedIds = Set<Int>()
        
        for i in 0..<GRID_SIZE {
            for j in 0..<GRID_SIZE {
                if let tile = grid[i][j] {
                    let tileId = tile.id
                    let posX = CGFloat(j) * (cellSize + 10) + 10
                    let posY = CGFloat(i) * (cellSize + 10) + 10
                    let targetFrame = CGRect(x: posX, y: posY, width: cellSize, height: cellSize)
                    
                    let tileView: UIView
                    if let tv = tileViews[tileId] {
                        tileView = tv
                        if animated {
                            UIView.animate(withDuration: 0.1) {
                                tileView.frame = targetFrame
                            }
                        } else {
                            tileView.frame = targetFrame
                        }
                    } else {
                        tileView = createTileView(tile: tile)
                        tileView.frame = targetFrame
                        // pop out 动画
                        tileView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                        tileView.alpha = 0
                        boardView.addSubview(tileView)
                        tileViews[tileId] = tileView
                        
                        UIView.animate(withDuration: 0.2,
                                       delay: 0,
                                       options: [.curveEaseOut],
                                       animations: {
                            tileView.transform = .identity
                            tileView.alpha = 1
                        }, completion: nil)
                    }
                    
                    updateTileView(tileView, with: tile)
                    usedIds.insert(tileId)
                }
            }
        }
        
        // 移除不用的 tileView
        for (tileId, tileView) in tileViews {
            if !usedIds.contains(tileId) {
                tileView.removeFromSuperview()
                tileViews.removeValue(forKey: tileId)
            }
        }
    }
    
    func createTileView(tile: Tile) -> UIView {
        let tileView = UIView()
        tileView.layer.cornerRadius = 3
        tileView.layer.masksToBounds = true
        
        // === 在这里给 tileView 添加长按手势 ===
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onTileLongPress(_:)))
        longPress.minimumPressDuration = 2.0 // 2秒
        tileView.addGestureRecognizer(longPress)
        
        // 用 tag 存储 tile 的 id，方便长按事件里找对应的 tile
        tileView.tag = tile.id
        
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.tag = 100
        tileView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: tileView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: tileView.trailingAnchor),
            label.topAnchor.constraint(equalTo: tileView.topAnchor),
            label.bottomAnchor.constraint(equalTo: tileView.bottomAnchor)
        ])
        
        return tileView
    }
    
    // === 长按回调，删除该 tile 并扣分 ===
    @objc func onTileLongPress(_ gesture: UILongPressGestureRecognizer) {
        // 只在长按刚刚触发的时机去处理（Began）
        guard gesture.state == .began else { return }
        
        if let tileView = gesture.view {
            let tileId = tileView.tag
            // 查找这个 tileId 在 grid 里的位置
            outer: for i in 0..<GRID_SIZE {
                for j in 0..<GRID_SIZE {
                    if let t = grid[i][j], t.id == tileId {
                        // 找到了
                        grid[i][j] = nil
                        let oldScore = score
                        score -= t.value   // 扣除相应分数
                        
                        // 刷新界面 & 显示扣分
                        updateUI(animated: false)
                        showScoreChange(diff: score - oldScore)
                        
                        // 自动存档
                        onSave()
                        break outer
                    }
                }
            }
        }
    }
    
    func updateTileView(_ tileView: UIView, with tile: Tile) {
        var bgColor: UIColor
        var textColor = UIColor(red: 0x77/255.0, green: 0x6e/255.0, blue: 0x65/255.0, alpha: 1)
        var fontSize: CGFloat = 30
        
        switch tile.value {
        case 2:
            bgColor = UIColor(red: 0xee/255.0, green: 0xe4/255.0, blue: 0xda/255.0, alpha: 1)
        case 4:
            bgColor = UIColor(red: 0xed/255.0, green: 0xe0/255.0, blue: 0xc8/255.0, alpha: 1)
        case 8:
            bgColor = UIColor(red: 0xf2/255.0, green: 0xb1/255.0, blue: 0x79/255.0, alpha: 1)
            textColor = .white
        case 16:
            bgColor = UIColor(red: 0xf5/255.0, green: 0x95/255.0, blue: 0x63/255.0, alpha: 1)
            textColor = .white
        case 32:
            bgColor = UIColor(red: 0xf6/255.0, green: 0x7c/255.0, blue: 0x5f/255.0, alpha: 1)
            textColor = .white
        case 64:
            bgColor = UIColor(red: 0xf6/255.0, green: 0x5e/255.0, blue: 0x3b/255.0, alpha: 1)
            textColor = .white
        case 128:
            bgColor = UIColor(red: 0xed/255.0, green: 0xcf/255.0, blue: 0x72/255.0, alpha: 1)
            textColor = .white
            fontSize = 24
        case 256:
            bgColor = UIColor(red: 0xed/255.0, green: 0xcc/255.0, blue: 0x61/255.0, alpha: 1)
            textColor = .white
            fontSize = 24
        case 512:
            bgColor = UIColor(red: 0xed/255.0, green: 0xc8/255.0, blue: 0x50/255.0, alpha: 1)
            textColor = .white
            fontSize = 24
        case 1024:
            bgColor = UIColor(red: 0xed/255.0, green: 0xc5/255.0, blue: 0x3f/255.0, alpha: 1)
            textColor = .white
            fontSize = 20
        case 2048:
            bgColor = UIColor(red: 0xed/255.0, green: 0xc2/255.0, blue: 0x2e/255.0, alpha: 1)
            textColor = .white
            fontSize = 20
        default:
            bgColor = .black
            textColor = .white
            fontSize = 20
        }
        
        tileView.backgroundColor = bgColor
        if let label = tileView.viewWithTag(100) as? UILabel {
            label.text = "\(tile.value)"
            label.textColor = textColor
            label.font = UIFont.boldSystemFont(ofSize: fontSize)
        }
    }
    
    func showScoreChange(diff: Int) {
        guard diff != 0 else { return }
        let diffLabel = UILabel()
        diffLabel.text = diff > 0 ? "+\(diff)" : "\(diff)"
        diffLabel.font = UIFont.systemFont(ofSize: 16)
        diffLabel.textColor = .white
        diffLabel.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        diffLabel.textAlignment = .center
        diffLabel.layer.cornerRadius = 5
        diffLabel.layer.masksToBounds = true
        
        view.addSubview(diffLabel)
        diffLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            diffLabel.leadingAnchor.constraint(equalTo: scoreContainer.trailingAnchor, constant: 8),
            diffLabel.centerYAnchor.constraint(equalTo: scoreContainer.centerYAnchor),
            diffLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            diffLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        UIView.animate(withDuration: 1.5, animations: {
            diffLabel.alpha = 0
            diffLabel.transform = CGAffineTransform(translationX: 0, y: -30)
        }, completion: { _ in
            diffLabel.removeFromSuperview()
        })
    }
    
    @objc func onToggleMode() {
        // 0->1->2->3->0
        mode = (mode + 1) % 4
        updateToggleButtonTitle()
    }
    
    func updateToggleButtonTitle() {
        let title: String
        switch mode {
        case 0: title = "模式: 正常"
        case 1: title = "模式: 只出2"
        case 2: title = "模式: 只出4"
        default: title = "模式: 作弊(512)"
        }
        toggleModeButton.setTitle(title, for: .normal)
    }
    
    // MARK: - 自动存档 / 读取
    func onSave() {
        let currentState = GameState(
            grid: grid,
            score: score,
            tileIdCounter: tileIdCounter,
            mode: mode,
            bestScore: bestScore
        )
        do {
            let data = try JSONEncoder().encode(currentState)
            let url = getSaveFileURL()
            try data.write(to: url)
        } catch {
            print("自动保存失败: \(error)")
        }
    }
    
    func onLoad() {
        let url = getSaveFileURL()
        if !FileManager.default.fileExists(atPath: url.path) {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let state = try JSONDecoder().decode(GameState.self, from: data)
            grid = state.grid
            score = state.score
            tileIdCounter = state.tileIdCounter
            mode = state.mode
            bestScore = state.bestScore
            history.removeAll()
        } catch {
            print("读取失败: \(error)")
        }
    }
    
    func getSaveFileURL() -> URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docDir.appendingPathComponent("2048.save")
    }
}
