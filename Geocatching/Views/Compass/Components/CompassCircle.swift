import SwiftUI

struct CompassCircle: View {
    let compassData: CompassData
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            
            ForEach(1..<12) { i in
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 2, height: 16)
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            
            Rectangle()
                .fill(Color.orange)
                .frame(width: 4, height: 20)
                .offset(y: -100)
                .rotationEffect(.degrees(0))
            
            ArrowShape()
                .fill(Color.red)
                .frame(width: 14, height: 70)
                .offset(y: -35)
                .rotationEffect(.degrees(-compassData.deviceHeading))
            
            if let azimuth = compassData.azimuth {
                ArrowShape()
                    .fill(Color.blue)
                    .frame(width: 18, height: 90)
                    .offset(y: -45)
                    .rotationEffect(.degrees(Double(azimuth) - compassData.deviceHeading))
                    .shadow(radius: 2)
            }
            
            Text("N")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.red)
                .offset(y: -120)
                .rotationEffect(.degrees(-compassData.deviceHeading))
        }
    }
}
