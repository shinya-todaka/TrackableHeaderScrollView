//
//  TrackableHeaderScrollView.swift
//  TrackableHeaderScrollView
//
//  Created by 戸高 新也 on 2024/12/20.
//

import SwiftUI

struct TrackableModifier: ViewModifier {
    @Environment(\.trackableHeaderCoordinator) var coordinator
    @State private var headerOffset: CGFloat = .zero
    let isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: headerOffset)
            .background {
                if let coordinator {
                    GeometryReader { geometry in
                        let frame = geometry.frame(in: .named(coordinator.scrollViewName))
                        
                        Color.clear
                            .onChange(of: frame) { newValue in
                                coordinator.update(newFrame: newValue, disabled: isDisabled)
                                self.headerOffset = coordinator.headerOffset
                            }
                    }
                    .hidden()
                } else {
                    EmptyView()
                }
            }
            .zIndex(1)
    }
}

extension View {
    // TrackableHeaderScrollViewの中だけで使える
    func trackable(disabled: Bool = false) -> some View {
        self.modifier(TrackableModifier(isDisabled: disabled))
    }
}

class TrackableHeaderCoordinator {
    
    let scrollViewName = UUID()
    
    // previous values
    private var isScrollingDown: Bool = false
    private var frame: CGRect = .zero
    private var headerOffsetWhenInverted: CGFloat = .zero
    private var disabled = false
    
    var headerOffset: CGFloat {
        guard !disabled else {
            return -frame.minY
        }
        
        guard frame.minY < 0 else {
            return .zero
        }
        
        return min(max(minHeaderOffset, headerOffsetWhenInverted), maxHeaderOffset)
    }
    
    private var minHeaderOffset: CGFloat {
        -frame.minY - frame.height
    }
    
    private var maxHeaderOffset: CGFloat {
        -frame.minY
    }
    
    func update(newFrame: CGRect, disabled: Bool) {
        let isScrollingDown = newFrame.minY < frame.minY
        
        if isScrollingDown != self.isScrollingDown {
            self.headerOffsetWhenInverted = headerOffset
        }
        
        self.disabled = disabled
        self.frame = newFrame
        self.isScrollingDown = isScrollingDown
    }
}

struct TrackableHeaderCoordinatorEnvironmentKey: EnvironmentKey {
    static var defaultValue: TrackableHeaderCoordinator?
}

extension EnvironmentValues {
    var trackableHeaderCoordinator: TrackableHeaderCoordinator? {
        get { self[TrackableHeaderCoordinatorEnvironmentKey.self] }
        set { self[TrackableHeaderCoordinatorEnvironmentKey.self] = newValue }
    }
}

struct TrackableHeaderScrollView<Content: View>: View {

    @ViewBuilder private let content: () -> Content

    private let coordinator = TrackableHeaderCoordinator()
    
    var body: some View {
        scrollView
    }
    
    private var scrollView: some View {
        ScrollView {
            content()
                .environment(\.trackableHeaderCoordinator, coordinator)
        }
        .coordinateSpace(name: coordinator.scrollViewName)
    }
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
}


#Preview("Simple Header") {
    TrackableHeaderScrollView {
        VStack {
            Color.red
                .frame(height: 100)
                .trackable()
            
            ForEach(0..<100) { index in
                Text("\(index)")
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview("Simple Header ignoreSafeArea") {
    TrackableHeaderScrollView {
        VStack {
            Color.red
                .frame(height: 100)
                .trackable()
            
            ForEach(0..<100) { index in
                Text("\(index)")
                    .frame(maxWidth: .infinity)
            }
        }
    }
    .ignoresSafeArea()
}

#Preview("Simple Header navigation title") {
    NavigationView {
        TrackableHeaderScrollView {
            Color.red
                .frame(height: 100)
                .trackable()
            
            VStack {
                ForEach(0..<100) { index in
                    Text("\(index)")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("title")
    }
}

#Preview("Simple Header Pushed View") {
    NavigationView {
        NavigationLink {
            TrackableHeaderScrollView {
                VStack {
                    Color.red
                        .frame(height: 100)
                        .trackable()
                    
                    ForEach(0..<100) { index in
                        Text("\(index)")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        } label: {
            Text("push")
        }
    }
}
