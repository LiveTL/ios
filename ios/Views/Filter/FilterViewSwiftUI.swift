//
//  FilterViewSwiftUI.swift
//  ios
//
//  Created by Andrew Glaze on 8/21/21.
//

import SwiftUI
import RxSwift
//import RxFlow

struct FilterViewSwiftUI: View {
    @State private var selection: Organization?
    var services: AppServices
    //let stepper: RxFlow.Stepper
    let bag = DisposeBag()
    
    var body: some View {
        NavigationView {
            List(Organization.allCases, id: \.self, selection: $selection) { org in
                Text(org.description)
            }.onAppear() {
                selection = services.settings.orgFilter
            }
            .environment(\.editMode, Binding.constant(EditMode.active))
            .navigationBarTitle("Organization Filter")
            .navigationBarItems(trailing: Button(action: {print("Dismissed")}, label: {
                Text("Save")
            }))
        }
        
    }
}

struct FilterViewSwiftUI_Previews: PreviewProvider {
    static var previews: some View {
        FilterViewSwiftUI(services: AppServices()).environment(\.editMode, Binding.constant(EditMode.active))
    }
}
