import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var answer: String = ""
    @State private var mathProblem: String = ""
    @State private var correctAnswer = false
    @State private var submitted = false
    @State private var shakeEffect = false
    @State private var showStars = false
    @State private var correctStreak = 0

    @State private var audioPlayer: AVAudioPlayer?
    @FocusState private var isTextFieldFocused: Bool
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 6) // Change '6' based on how many bananas you want in one row before wrapping


    var body: some View {
        ZStack {
            // Use GeometryReader to read the container size
            GeometryReader { geometry in
                Image("monkey")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped() // Clip the image to the bounds of the frame
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // Center the image
            }
            .edgesIgnoringSafeArea(.all)
            VStack(spacing: 30) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<correctStreak, id: \.self) { _ in
                        Image("banana")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    }
                }
                
                if showStars {
                    HStack {
                        ForEach(0..<3, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .scaleEffect(5)
                                
                        }
                        .frame(width: 100, height: 100)
                    }
                }
                
                if !showStars {
                    Text("How much is")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .background(correctAnswer ? Color.green.opacity(0.8) : Color.clear)
                        .padding()
                }
                
                Text(mathProblem)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding()
                    .background(correctAnswer ? Color.green.opacity(0.8) : Color.teal.opacity(0.5))
                    .cornerRadius(10)
                    .scaleEffect(correctAnswer ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5), value: correctAnswer)
                    .onAppear(perform: generateMathProblem)
                
                
                if (!showStars) {
                    TextField("Enter answer", text: $answer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(submitted ? (correctAnswer ? Color.green : Color.red) : Color.yellow, lineWidth: 10))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .padding()
                        .keyboardType(.numberPad)
                        .frame(width: 300)
                        .modifier(ShakeEffect(shake: $shakeEffect))
                        .focused($isTextFieldFocused)
            
                
                    Button(action: checkAnswer) {
                        Text("Check Answer")
                            .bold()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func playSound(_ soundFileName: String) {
        guard let path = Bundle.main.path(forResource: soundFileName, ofType: nil) else { return }
        let url = URL(fileURLWithPath: path)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            // Couldn't load the sound file
            print("Couldn't load the sound file.")
        }
    }

    func generateMathProblem() {
        let number1 = Int.random(in: 0...10)
        let number2 = Int.random(in: 0...10)
        let isAddition = Bool.random()

        if isAddition {
            mathProblem = "\(number1) + \(number2) = ?"
        } else {
            let (larger, smaller) = number1 > number2 ? (number1, number2) : (number2, number1)
            mathProblem = "\(larger) - \(smaller) = ?"
        }
        answer = ""
        correctAnswer = false
        shakeEffect = false
        showStars = false
        submitted = false
        isTextFieldFocused = true
    }

    func checkAnswer() {
        submitted = true
        let components = mathProblem.components(separatedBy: " ")
        if let number1 = Int(components[0]), let number2 = Int(components[2]) {
            let addition = mathProblem.contains("+");
            let calculatedAnswer = addition ? number1 + number2 : number1 - number2
            correctAnswer = Int(answer) == calculatedAnswer

            if correctAnswer {
                correctStreak += 1
                showStars = true
                mathProblem = "\(number1) \(addition ? "+" : "-") \(number2) = \(calculatedAnswer)"
                playSound("monkey.wav")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // Delay for 5 seconds
                    self.generateMathProblem()
                }
            } else {
                if (correctStreak > 0) {
                    correctStreak -= 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Delay for 5 seconds
                    answer = ""
                }
                shakeEffect = true
                showStars = false
                playSound("uhh.wav")
            }
            isTextFieldFocused = true
        }
    }
}

struct ShakeEffect: GeometryEffect {
    @Binding var shake: Bool
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    init(shake: Binding<Bool>) {
        _shake = shake
        animatableData = shake.wrappedValue ? 1 : 0
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard shake else { return ProjectionTransform(.identity) }
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

