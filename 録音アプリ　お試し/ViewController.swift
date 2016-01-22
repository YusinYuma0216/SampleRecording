//
//  ViewController.swift
//  録音アプリ　お試し
//
//  Created by Yuma Yamamoto on 2016/01/22.
//  Copyright © 2016年 Yuma Yamamoto. All rights reserved.
//


import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var recorder: AVAudioRecorder!
    var meterTimer: NSTimer!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var apcLabel: UILabel!
    @IBOutlet weak var peakLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pushRecord(sender: AnyObject) {
        
        if recorder != nil && recorder.recording {
            self.recorder.pause()
            self.recordButton.setTitle("Continue", forState:.Normal)
        } else {
            self.stopButton.enabled = true
            self.recordButton.setTitle("Pause", forState:.Normal)
            self.recordWithPermission(true)
            
        }
    }
    
    @IBAction func pushStop(sender: UIButton) {
        
        if recorder == nil {
            return
        }
        
        print("stop")
        self.recorder.stop()
        self.meterTimer.invalidate()
        
        self.recordButton.setTitle("Record", forState:.Normal)
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        var error: NSError?
        if !session.setActive(false, error: &error) {
            print("could not make session inactive")
            if let e = error {
                print(e.localizedDescription)
                return
            }
        }
        self.stopButton.enabled = false
        self.recordButton.enabled = true
    }
    
    func recordWithPermission(setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // ios 8 and later
        if (session.respondsToSelector("requestRecordPermission:")) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.1,
                        target:self,
                        selector:"updateAudioMeter:",
                        userInfo:nil,
                        repeats:true)
                } else {
                    print("Permission to record not granted")
                }
            })
        } else {
            print("requestRecordPermission unrecognized")
        }
    }
    
//    func setSessionPlayAndRecord() {
//        let session:AVAudioSession = AVAudioSession.sharedInstance()
//        var error: NSError?
//        if !session.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions:error) {
//            print("could not set session category")
//            if let e = error {
//                print(e.localizedDescription)
//            }
//        }
    
    
    
    
    
//    do{
//            try session.setActive(true)
//            
//        }catch {
//        
//    }
//        if !session.setActive(true, error: &error) {
//            print("could not make session active")
//            if let e = do{
//                print(e.localizedDescription)
//            }
//        }
//    }
    
    @IBAction func startRecord() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord,
                withOptions: .DuckOthers)
            do {
                try session.setActive(true)
                print("Successfully activated the audio session")
                
                session.requestRecordPermission{allowed in
                    
                    if allowed{
                        self.startRecordingAudio()
                    } else {
                        print("We don't have permission to record audio");
                    }
                    
                }
            } catch {
                print("Could not activate the audio session")
            }
            
        } catch let error as NSError {
            print("An error occurred in setting the audio " +
                "session category. Error = \(error)")
        }
    }
    
    func startRecordingAudio() {
        
    }
    
    
    
    func setupRecorder() {
        
        let dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask,true)
        var docsDir: AnyObject = dirPaths[0]
        var soundFilePath = docsDir.stringByAppendingPathComponent("Recorded.m4a")
        let soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        
        var recordSettings = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        var error: NSError?
        self.recorder = AVAudioRecorder(URL: soundFileURL!, settings: recordSettings as [NSObject : AnyObject], error: &error)
        if let e = error {
            print(e.localizedDescription)
        } else {
            self.recorder.delegate = self
            self.recorder.meteringEnabled = true
            self.recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
            
        }
    }
    
    func updateAudioMeter(timer:NSTimer) {
        
        if recorder.recording {
            let dFormat = "%02d"
            let min:Int = Int(recorder.currentTime / 60)
            let sec:Int = Int(recorder.currentTime % 60)
            let s = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
            statusLabel.text = s
            recorder.updateMeters()
            let apc0 = recorder.averagePowerForChannel(0)
            let peak0 = recorder.peakPowerForChannel(0)
            
            let peak = String(format:"Peak:%@", peak0.description)
            peakLabel.text = peak
            
            let apc = String(format:"Avg:%@", apc0.description)
            apcLabel.text = apc
        }
    }
    
}

extension ViewController : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder,
        successfully flag: Bool) {
            print("finished recording \(flag)")
            recordButton.setTitle("Record", forState:.Normal)
            
            // iOS8 and later
            let alert = UIAlertController(title: "Recorder",
                message: "Finished Recording",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Keep", style: .Default, handler: {action in
                print("keep was tapped")
            }))
            alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: {action in
                print("delete was tapped")
                self.recorder.deleteRecording()
                self.recorder = nil
                
            }))
            self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder,
        error: NSError?) {
            print("\(error!.localizedDescription)")
    }
}