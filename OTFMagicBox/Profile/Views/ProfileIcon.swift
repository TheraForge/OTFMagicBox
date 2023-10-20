//
//  ProfileIcon.swift
//  OTFMagicBox
//
//  Created by Arslan Raza on 30/05/2023.
//

import SwiftUI

struct ProfileIcon: View {
    var image: UIImage
    var body: some View {
        Image(uiImage: image)
            .iconStyle()
            .frame(width: Metrics.IMAGE_VIEW_WIDTH, height: Metrics.IMAGE_VIEW_HEIGHT, alignment: .center)
    }
}

struct ProfileIcon_Previews: PreviewProvider {
    static var previews: some View {
        ProfileIcon(image: UIImage(named: ModuleAppYmlReader().profileData!.profileImage)!)
            .previewLayout(.fixed(width: Metrics.IMAGE_VIEW_WIDTH, height: Metrics.IMAGE_VIEW_HEIGHT))
    }
}
