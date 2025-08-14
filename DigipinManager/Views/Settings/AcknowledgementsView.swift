//
//  AcknowledgementsView.swift
//  DigipinManager
//
//  Created by Rishi Singh on 14/08/25.
//

import SwiftUI

struct AcknowledgementsView: View {
    var body: some View {
        List {
            Text("""
DIGIPIN codes are calculated using an offline algorithm modeled after official geospatial principles supported by the Government of India, including the Digital Address Code initiative by India Post and mapping resources from ISRO and the Survey of India.
Credits
  • Department of Posts, Government of India
  • Indian Institute of Technology (IIT) Hyderabad
  • National Remote Sensing Centre (NRSC), ISRO
  • Foundation for Science Innovation and Development (FSID) at the Indian Institute of Science (IISc)
  • National Informatics Centre (NIC), Government of India
""")
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AcknowledgementsView()
}
