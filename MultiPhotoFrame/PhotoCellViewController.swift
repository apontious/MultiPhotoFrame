/*
     File: PhotoCellViewController.h 
 Abstract: The view controller for each Photo Cell View. It is responsible for setting up the representedObject dictionary from a URL, determining the photo orientation, and providing the images for dragging.
  
  Version: 1.3 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2013 Apple Inc. All Rights Reserved. 
  
 Modifications:
     Copyright (c) 2017 Andrew Pontious.
     Some right reserved: http://opensource.org/licenses/mit-license.php
*/

import Cocoa

let kImageUrlKey = "imageURL"
let kLabelKey = "label"

@objc public enum PhotoCellOrientation: Int {
	case landscape
	case portrait
}
class PhotoCellViewController: NSViewController {

	@IBOutlet private var photoView: NSImageView!
	@IBOutlet private var labelView: NSImageView!

	private let url: URL

	public func isEqual(toDraggingItem draggingItem: NSDraggingItem) -> Bool {
		guard let draggingItemURL = draggingItem.item as? URL else {
			return false
		}

		// Using isEqual: to compare this object's URL to a draggingItem's URL in Obj-C doesn't seem to work.
		// TODO: try comparing for equality again when everything's in Swift, see if that changes behavior.
		return draggingItemURL == url
	}
	
	override func loadView() {
		super.loadView()
		photoView.unregisterDraggedTypes()
	}

	required init?(coder: NSCoder) {
		preconditionFailure("Shouldn't call this initializer")
	}

	override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		preconditionFailure("Shouldn't call this initializer")
	}

	public init(withURL url: URL) {
		self.url = url
		super.init(nibName: "PhotoCellView", bundle: nil)!

		let mdItemRef = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL!) as MDItem!
		let commentStr = MDItemCopyAttribute(mdItemRef, kMDItemFinderComment) as? String ?? ""

		representedObject = [kImageUrlKey: url, kLabelKey: commentStr]
		loadView()
	}

	public var photoCellOrientation: PhotoCellOrientation {
		let orientation: PhotoCellOrientation

		if let image = self.photoView.image {
			let imageSize = image.size;
			if (imageSize.width >= imageSize.height) {
				orientation = .landscape;
			} else {
				orientation = .portrait;
			}
		} else {
			orientation = .landscape;
		}

		return orientation
	}

	private func cacheImageOfView(_ view: NSView) -> NSImage {
		let bitmapImageRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
		bzero(bitmapImageRep.bitmapData, bitmapImageRep.bytesPerRow * bitmapImageRep.pixelsHigh)
		view.cacheDisplay(in: view.bounds, to: bitmapImageRep)
		let imageCache = NSImage(size: bitmapImageRep.size)
		imageCache.addRepresentation(bitmapImageRep)

		return imageCache;
	}

	/* This method is called by MultiPhotoView to generate the dragging image components. The dragging image components for a Photo Cell View consist of the matte background, photo image, and comment label.
	*/
	public func imageComponentsForDrag() -> [NSDraggingImageComponent] {
		var components = [NSDraggingImageComponent]()
		
		// Each dragging component image animates independently. Since the photoView and labelView are subviews of the matte background view, we need to hide them so they are not included in the background image component snapshot.
		photoView.isHidden = true
		labelView.isHidden = true
		
		// dragging Image Components are painted from back to front, so but the background image first in the array.
		let backgroundImageComponent = NSDraggingImageComponent(key: "background")
		backgroundImageComponent.frame = view.bounds
		backgroundImageComponent.contents = cacheImageOfView(self.view)
		components.append(backgroundImageComponent)
		
		// The matte background image snapshot is complete, we can show these views again.
		photoView.isHidden = false
		labelView.isHidden = false
		
		// snapshot the photo image
		let iconImageComponent = NSDraggingImageComponent(key: NSDraggingImageComponentIconKey)
		iconImageComponent.frame = self.view.convert(photoView.bounds, from: photoView)
		iconImageComponent.contents = cacheImageOfView(photoView)
		components.append(iconImageComponent)
		
		// snapshot the label image
		let labelImageComponent = NSDraggingImageComponent(key: NSDraggingImageComponentLabelKey)
		labelImageComponent.frame = self.view.convert(photoView.bounds, from: labelView)
		labelImageComponent.contents = cacheImageOfView(labelView)
		components.append(labelImageComponent)
		
		return components
	}
}
