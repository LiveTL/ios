//
//  HomeView.swift
//  ios
//
//  Created by Mason Phillips on 12/30/21.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(UIColor(named: "LiveTL Logo Dark")!),
                Color(UIColor(named: "LiveTL Logo Light")!)
            ], startPoint: .bottomLeading, endPoint: .topTrailing)
                .ignoresSafeArea()
                
            ScrollView {
                VStack {
                    ForEach(1..<5) { _ in
                        Row()
                    }
                }
            }
        }
    }
}

struct Row: View {
    var body: some View {
        VStack {
            Header()
                .padding(.horizontal)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(1..<5) { _ in
                        StreamContent()
                    }
                    
                    Spacer()
                }
            }
                .padding(.leading)
        }
    }
}

struct Header: View {
    var body: some View {
        HStack {
            Text("Service")
            Spacer()
            Button {} label: {
                HStack {
                    Text("See More")
                    Text("chevron-right")
                        .font(.custom("FontAwesome5Pro-Regular", size: 18))
                }
            }
        }
    }
}

struct StreamContent: View {
    var body: some View {
        ZStack(alignment: .center) {
//            Color(.red.withAlphaComponent(0.5))
            ZStack {
                Image("sample_thumbnail")
                Color(.black.withAlphaComponent(0.4))
            }
            
            VStack(alignment: .leading) {
                CircularProfileIcon()
                    .padding(.top, 5)
                    .padding(.leading, 5)

                Spacer()
                
                Text("【#生スバル​】おはようスバル：FREE TALK【ホロライブ/大空スバル】")
                    .font(.title2)
                    .frame(width: 305, height: 30, alignment: .leading)
                    .fixedSize()
                    .truncationMode(.tail)
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                
                Text("Streaming since 7 PM")
                    .padding(.leading, 9)
                    .foregroundColor(.white)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(maxWidth: 350)
    }
}

struct CircularProfileIcon: View {
    var body: some View {
        ZStack {
            Color(.gray)
                .cornerRadius(25)
            HStack {
                Image("sample_profile")
                    .resizable()
                    .frame(width: 48)
                    .cornerRadius(24)
                
                Spacer(minLength: 2)
                
                Text("Subaru Ch. 大空スバル")
                    .foregroundColor(.white)
                    .frame(height: 30)
                    .padding(.trailing, 2)
            }
        }
        .frame(width: 240, height: 50)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
//        HomeView()
//            .preferredColorScheme(.dark)
    }
}
