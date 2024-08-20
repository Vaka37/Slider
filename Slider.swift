//
//  File.swift
//  Slider
//
//  Created by Vakil on 20.08.2024.
//

import Foundation
import SwiftUI


public struct CustomSlider<Value, Track, Fill, Thumb>: View
    where Value: BinaryFloatingPoint, Value.Stride: BinaryFloatingPoint, Track: View, Fill: View, Thumb: View
{
    @Binding var value: Value
    let bounds: ClosedRange<Value>
    let step: Value
    let minimumValueLabel: View?
    let maximumValueLabel: View?
    let onEditingChanged: ((Bool) -> Void)?
    let track: () -> Track
    let fill: (() -> Fill)?
    let thumb: () -> Thumb
    let thumbSize: CGSize
    let endingAction: VoidHandler

    @State private var xOffset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @State private var trackSize: CGSize = .zero

    public  init(
        value: Binding<Value>,
        in bounds: ClosedRange<Value> = 0 ... 1,
        step: Value = 1,
        minimumValueLabel: Text? = nil,
        maximumValueLabel: Text? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil,
        track: @escaping () -> Track,
        fill: (() -> Fill)?,
        thumb: @escaping () -> Thumb,
        thumbSize: CGSize,
        endindAction: @escaping VoidHandler
    ) {
        _value = value
        self.bounds = bounds
        self.step = step
        self.onEditingChanged = onEditingChanged
        self.track = track
        self.fill = fill
        self.thumb = thumb
        self.thumbSize = thumbSize
        endingAction = endindAction
    }

    private var percentage: Value {
        1 - (bounds.upperBound - value) / (bounds.upperBound - bounds.lowerBound)
    }

    private var fillWidth: CGFloat {
        trackSize.width * CGFloat(percentage)
    }

    public var body: some View {
        VStack(alignment: .center) {
            HStack {
                minimumValueLabel
                ZStack {
                    track()
                        .measureSize {
                            let firstInit = (trackSize == .zero)
                            trackSize = $0
                            if firstInit {
                                xOffset = (trackSize.width - thumbSize.width) * CGFloat(percentage)
                                lastOffset = xOffset
                            }
                        }
                    fill?()
                        .position(x: fillWidth - trackSize.width / 2, y: trackSize.height / 2)
                        .frame(width: fillWidth, height: trackSize.height)
                }
                .frame(width: trackSize.width, height: trackSize.height)
                .overlay(
                    thumb()
                        .position(
                            x: thumbSize.width / 2,
                            y: thumbSize.height / 2
                        )
                        .frame(width: thumbSize.width, height: thumbSize.height)
                        .offset(x: xOffset)
                        .gesture(DragGesture(minimumDistance: 0).onChanged { gestureValue in
                            if abs(gestureValue.translation.width) < 0.1 {
                                lastOffset = xOffset
                                onEditingChanged?(true)
                            }
                            let availableWidth = trackSize.width - thumbSize.width
                            xOffset = max(0, min(lastOffset + gestureValue.translation.width, availableWidth))
                            let newValue = (bounds.upperBound - bounds.lowerBound) * Value(xOffset / availableWidth) +
                                bounds.lowerBound
                            let steppedNewValue = (round(newValue / step) * step)
                            value = min(bounds.upperBound, max(bounds.lowerBound, steppedNewValue))
                        }.onEnded { _ in
                            onEditingChanged?(false)
                            endingAction()
                        }),
                    alignment: .leading
                )
                maximumValueLabel
            }
        }
    }
}


public struct SliderView: View {
    private let thumbRadius: CGFloat = 30
    @State private var value = Date().timeIntervalSince1970
    @State var onEditingChanged = false
    let endindAction: VoidHandler
    @State private var rangeValue: ClosedRange<Double>
    public var body: some View {
        GeometryReader { gr in
            VStack(alignment: .center) {
                Spacer()
                CustomSlider(
                    value: $value,
                    in: rangeValue,
                    onEditingChanged: { started in
                        withAnimation {
                            onEditingChanged = started
                        }
                    },
                    track: {
                        Capsule()
                            .foregroundColor(.black.opacity(0.4))
                            .frame(width: gr.size.width - 100, height: 5)
                            .overlay {
                                Capsule()
                                    .stroke(.white)
                                    .frame(width: gr.size.width - 100, height: 5)
                            }
                    },
                    fill: {
                        Capsule()
                            .foregroundColor(Color.blue)
                    },
                    thumb: {
                        ZStack {
                            VStack {
                                if onEditingChanged {
                                    Text(Date(timeIntervalSince1970: TimeInterval(value)).time() ?? "")
                                        .foregroundStyle(Color.white)
                                        .font(.headline)
                                        .padding(.horizontal)
                                        .fixedSize()
                                        .background {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(.black.opacity(0.4))
                                                .blur(radius: 3)
                                                .frame(height: 40)
                                        }
                                }
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                        .overlay {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 30)
                                Circle()
                                    .foregroundColor(Color.blue)
                                    .frame(width: 14)
                                Circle()
                                    .stroke(.black, lineWidth: 1)
                                    .frame(width: 30)
                            }
                        }
                    },
                    thumbSize: CGSize(width: thumbRadius, height: thumbRadius), endindAction: {
                        actionTap()
                    }
                )
                Spacer()
            }
        }
    }

    public init(endindAction: @escaping VoidHandler, rangeValue: ClosedRange<Double>) {
        self.endindAction = endindAction
        self.rangeValue = rangeValue
    }
}

