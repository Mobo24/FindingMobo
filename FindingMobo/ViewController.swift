//
//  ViewController.swift
//  FindingMobo
//
//  Created by Mobolaji Moronfolu on 1/30/20.
//  Copyright © 2020 Mobolaji Moronfolu. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController, UINavigationControllerDelegate {
    var stackView1 = UIStackView()
    var animationTimer: Timer?
    var nameLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 10, height: 10))


    @IBOutlet weak var Fmblabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView?
    
    let chosephoto = UIButton()
    let sharebutton = UIButton()

   override func viewDidLoad() {
    
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .yellow
        ConfigureStackview()
        setupControls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        animationTimer?.invalidate()
    }

    func configureImageView(){
        
        photoImageView?.translatesAutoresizingMaskIntoConstraints = false
        photoImageView?.heightAnchor.constraint(equalToConstant: 400).isActive = true
        photoImageView?.widthAnchor.constraint(equalToConstant: 400).isActive = true
        photoImageView?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        photoImageView?.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        photoImageView?.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
        photoImageView?.layer.masksToBounds = true
        photoImageView?.layer.borderWidth = 5

    }
    lazy var detectionRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: FindingMobo().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processDetections(for: request, error: error)
            })
            request.imageCropAndScaleOption = .scaleFit
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    private func updateDetections(for image: UIImage) {

        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do {
                try handler.perform([self.detectionRequest])
            } catch {
                print("Failed to perform detection.\n\(error.localizedDescription)")
            }
        }
    }
    
    private func processDetections(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                print("Unable to detect anything.\n\(error!.localizedDescription)")
                self.nameLabel.text = "NO MOBO!"
                return
            }
        
            let detections = results as! [VNRecognizedObjectObservation]
            self.drawDetectionsOnPreview(detections: detections)
        }
    }
    
    func drawDetectionsOnPreview(detections: [VNRecognizedObjectObservation]) {
        guard let image = self.photoImageView?.image else {
            return
        }
        
        let imageSize = image.size
        let scale: CGFloat = 0
        DispatchQueue.main.async {
                   self.nameLabel.text = "MOBO FOUND"
                       return
                   }
               
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)

        image.draw(at: CGPoint.zero)

        for detection in detections {
            
            print(detection.labels.map({"\($0.identifier) confidence: \($0.confidence)"}).joined(separator: "\n"))
            print("------------")
            
            let boundingBox = detection.boundingBox
            let rectangle = CGRect(x: boundingBox.minX*image.size.width, y: (1-boundingBox.minY-boundingBox.height)*image.size.height, width: boundingBox.width*image.size.width, height: boundingBox.height*image.size.height)
            UIColor(red: 0, green: 1, blue: 0, alpha: 0.4).setFill()
            UIRectFillUsingBlendMode(rectangle, CGBlendMode.normal)
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.photoImageView?.image = newImage
    }
}

extension ViewController: UIImagePickerControllerDelegate{
    
    
    @objc func showImagePickerControllerActionSheet(sender:UIButton){
        self.shake(sender)
        let photoLibraryAction = UIAlertAction(title: "Chose from library", style: .default){ (action) in
            self.showImagePickerController(source: .photoLibrary)
        }
        let cameraAction = UIAlertAction(title: "Take from Camera", style: .default){ (action) in
            self.showImagePickerController(source: .camera)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
      
        AlertService.showAlert(style: .actionSheet, title: "Choose Yor Image!", message: nil, actions: [photoLibraryAction, cameraAction, cancelAction], completion: nil)
    
    }
    @objc func shareActivities(){
        if let image = photoImageView?.image {
            let vc = UIActivityViewController(activityItems: ["Testing out finding mobo",image], applicationActivities: [])
            present(vc, animated: true)
        }
    }
    
    func showImagePickerController(source: UIImagePickerController.SourceType){
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = source
        present(imagePickerController, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.photoImageView?.image = editedImage
            updateDetections(for: editedImage)
        }else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            self.photoImageView?.image = originalImage
            updateDetections(for: originalImage)
        }
        dismiss(animated: true, completion: nil)
    }
    func ConfigureStackview(){
        view.addSubview(stackView1)
        stackView1.axis = .vertical
        stackView1.alignment = .center
        stackView1.spacing =  20
        setStackViewConstraints()
        configureImageView()
    }
    func setupControls(){
        Fmblabel.translatesAutoresizingMaskIntoConstraints = false
        Fmblabel.textColor = .black
        Fmblabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 1).isActive = true
        Fmblabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1).isActive = true
        
        chosephoto.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "plus")
        chosephoto.setImage(image, for: .normal)
        view.addSubview(chosephoto)
        chosephoto.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20).isActive = true
        chosephoto.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        chosephoto.heightAnchor.constraint(equalToConstant: 22).isActive = true
        chosephoto.widthAnchor.constraint(equalToConstant: 20).isActive = true
        chosephoto.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant:30).isActive = true
        chosephoto.addTarget(self, action: #selector(showImagePickerControllerActionSheet), for: .touchUpInside)
       
        sharebutton.translatesAutoresizingMaskIntoConstraints = false
        let smallConfiguration = UIImage.SymbolConfiguration(scale: .large)
        let image2 = UIImage(systemName: "square.and.arrow.up.fill", withConfiguration: smallConfiguration )
        sharebutton.setImage(image2, for: .normal)
        view.addSubview(sharebutton)
        sharebutton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 20).isActive = true
        sharebutton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        sharebutton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        sharebutton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        sharebutton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant:-30).isActive = true
        sharebutton.addTarget(self, action: #selector(shareActivities), for: .touchUpInside)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 1).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        nameLabel.layer.borderWidth = 2.0
        nameLabel.layer.borderColor = UIColor.darkGray.cgColor
        nameLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant:60).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: sharebutton.trailingAnchor, constant:-50).isActive = true
        let fontSize = self.nameLabel.font.pointSize;
        nameLabel.font = UIFont(name: "HelveticaNeue", size: fontSize)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .black
        nameLabel.layer.cornerRadius = (nameLabel.frame.size.height)/2.0
        nameLabel.layer.masksToBounds = true
        nameLabel.text = "NO MOBO! UPLOAD AN IMAGE!"
       
    }
    
    @objc func shake(_ viewToAnimate: UIView){
        
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity:0.5, options: .curveEaseIn, animations: {
            viewToAnimate.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }){(_) in
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity:0.2, options: .curveEaseIn, animations: {
                viewToAnimate.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        }}
    
    func setStackViewConstraints(){
        stackView1.translatesAutoresizingMaskIntoConstraints = false
        stackView1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        stackView1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        stackView1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 20).isActive = true
        stackView1.isUserInteractionEnabled = true
        stackView1.backgroundColor = .green
        stackView1.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 80).isActive = true
    }
}
