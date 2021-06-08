//
//  MusicPlayerViewController.swift
//  MusicAll
//
//  Created by Patryk Krajnik on 10/01/2021.
//

import UIKit
import AVFoundation
import MediaPlayer

class MusicPlayerViewController: UIViewController {
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var currentTimeLeftLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressSlider: UISlider!
    
    @IBOutlet weak var songArtworkView: UIImageView!
    
    @IBOutlet weak var playPauseButtonView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    private var timer: Timer!
    static var player: AVPlayer?
    
    var songTitle = "Song Title"
    var songArtist = "Artist"
    var songImage = "album_placeholder.png"
    var isJsonOffline = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressSlider.addTarget(self, action: #selector(userSeek), for: UIControl.Event.valueChanged)
        
        initSongPlaying()
        setupAVAudioSession()
        setupInitialUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateCommandCenterInfo(songName: songTitle, songArtist: songArtist, imageName: songImage)
    }
    
    func setupInitialUI() {
        makeItRounded(view: playPauseButtonView, newSize: playPauseButtonView.frame.width)
        setupTitles()
        setupArtwork()
        progressSlider.value = 0.0
        playButton.isHidden = true
        pauseButton.isHidden = false
    }
    
    func makeItRounded(view: UIView, newSize: CGFloat) {
        let saveCenter: CGPoint = view.center
        let newFrame: CGRect = CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: newSize, height: newSize)
        
        view.frame = newFrame
        view.layer.cornerRadius = newSize / 2.0
        view.clipsToBounds = true
        view.center = saveCenter
    }
    
    func setupTitles() {
        if songTitle != "" {
            songTitleLabel.text = songTitle
        } else {
            songTitleLabel.isHidden = true
        }
        
        if songArtist != "" {
            artistNameLabel.text = songArtist
        } else {
            artistNameLabel.isHidden = true
        }
    }
    
    func setupArtwork() {
        songArtworkView.image = UIImage(named: songImage)
    }
    
    func updateButtons() {
        switch MusicPlayerViewController.isPlaying() {
        case true:
            playButton.isHidden = true
            pauseButton.isHidden = false
        default:
            playButton.isHidden = false
            pauseButton.isHidden = true
        }
    }
    
    func pauseSong() {
        MusicPlayerViewController.player?.pause()
        updateButtons()
        
        UIView.animate(
            withDuration: 1.0,
            delay: 0.0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                self.songArtworkView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            },
            completion: nil)
    }
    
    func playSong() {
        MusicPlayerViewController.player?.play()
        updateButtons()
        
        UIView.animate(
            withDuration: 1.0,
            delay: 0.0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .curveEaseIn,
            animations: {
                self.songArtworkView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            },
            completion: nil)
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        playSong()
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        pauseSong()
    }
    
    func initSongPlaying() {
        var songURL = ""
        let playerItem: AVPlayerItem?

        if MusicPlayerViewController.player != nil {
            MusicPlayerViewController.player?.pause()
        }

        switch isJsonOffline {
        case true:
            songURL = Bundle.main.path(forResource: "\(songArtist) - \(songTitle)", ofType: "mp3")!
            playerItem = AVPlayerItem(url: URL(fileURLWithPath: songURL))
        default:
            songURL = "Here is a place for URL to your API with chosen song"
            let changedURL = songURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            playerItem = AVPlayerItem(url: URL(string: changedURL!)!)
        }

        MusicPlayerViewController.player = AVPlayer(playerItem: playerItem)
        MusicPlayerViewController.player?.volume = 1.0
        MusicPlayerViewController.player?.play()
        startTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(sender:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    @objc func playerDidFinishPlaying(sender: Notification) {
        initSongPlaying()
    }
    
    @objc func setupTimers() {
        if (MusicPlayerViewController.player != nil) && !(MusicPlayerViewController.player?.currentItem?.duration.seconds.isNaN)! {
            progressSlider.maximumValue = Float((MusicPlayerViewController.player?.currentItem?.duration.seconds)!)
            progressSlider.value = Float((MusicPlayerViewController.player?.currentTime().seconds)!)
        }
        
        setupCurrentTime()
        
        if progressSlider.value > 0.0 {
            activityIndicator.isHidden = true
        }
    }
    
    func setupCurrentTime() {
        if progressSlider.value.isNaN {return}
        
        let currentDuration = Int(progressSlider.value)
        let minutes = currentDuration / 60
        let seconds = currentDuration % 60
        
        currentTimeLabel.text = NSString(format: "%i:%02i", minutes, seconds) as String
        setupCurrentTimeLeft(currentDuration: currentDuration)
    }
    
    func setupCurrentTimeLeft(currentDuration: Int) {
        if progressSlider.maximumValue.isNaN {return}
        
        let totalDuration = Int(progressSlider.maximumValue)
        let currentDurationLeft = totalDuration - currentDuration
        let minutes = currentDurationLeft / 60
        let seconds = currentDurationLeft % 60
        
        currentTimeLeftLabel.text = NSString(format: "-%i:%02i", minutes, seconds) as String
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(setupTimers), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
    
    @objc func userSeek() {
        let value = progressSlider.value
        if (MusicPlayerViewController.player != nil) && (MusicPlayerViewController.player?.currentTime() != nil) {
            MusicPlayerViewController.player?.seek(to: CMTime(seconds: Double(value), preferredTimescale: (MusicPlayerViewController.player?.currentTime().timescale)!))
        }
    }
    
    private func setupAVAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            debugPrint("Playback OK")
            
            UIApplication.shared.beginReceivingRemoteControlEvents()
            setupCommandCenterRemoteControl()
        } catch {
            print(error)
        }
    }
    
    func setupCommandCenterRemoteControl() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        
        commandCenter.playCommand.addTarget { [unowned self] event in
            playSong()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            pauseSong()
            return .success
        }
    }
    
    static func isPlaying() -> Bool {
        return (player != nil) && (player!.rate != 0) && (player!.error == nil)
    }
}

/* TODO LIST:
- Pokombinować żeby dodawać do ulubionych
- Dodać żeby player się minimalizował i można było wrócić do obecnie grającej piosenki

Rozdzielić obsługę playera od ViewControllera, tutaj zostawić tylko interakcję a logikę osobno.
 - Potem dodać observera nad rate playera i na tej podstawie aktualizować buttony
 - W MusicPlayerViewControllerze zrobić strukturę, do której dodaję tytuł i artystę. Jeżeli po wejściu zgadzają się nazwy to nie odtwarza na nowo, tylko update UI
 */
