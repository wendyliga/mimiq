class Mimiq < Formula
    desc "mimiq is simple executable to record your Xcode simulator and convert it to GIF"
    homepage "https://github.com/wendyliga/mimiq"
    url "https://github.com/wendyliga/mimiq/releases/download/0.0.1/mimiq"
    version "0.0.1"
    sha256 "b80fec03bb31f6d3cec785df03ee355655caae068512faed596abe2cb1fc4f27"
  
    bottle :unneeded

    def install
        bin.install "mimiq"
    end
  end
  