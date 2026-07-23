package audio

import (
	"math"
)

type Sample float64

type AudioBuffer struct {
	Samples    []Sample
	SampleRate int
	Channels   int
}

func NewAudioBuffer(size, sampleRate, channels int) *AudioBuffer {
	return &AudioBuffer{
		Samples:    make([]Sample, size),
		SampleRate: sampleRate,
		Channels:   channels,
	}
}

func (ab *AudioBuffer) Length() int {
	return len(ab.Samples)
}

func (ab *AudioBuffer) Duration() float64 {
	return float64(len(ab.Samples)) / float64(ab.SampleRate*ab.Channels)
}

func (ab *AudioBuffer) Normalize() {
	max := Sample(0)
	for _, s := range ab.Samples {
		if math.Abs(float64(s)) > float64(max) {
			max = Sample(math.Abs(float64(s)))
		}
	}

	if max > 0 {
		for i := range ab.Samples {
			ab.Samples[i] /= max
		}
	}
}

func (ab *AudioBuffer) Amplify(gain float64) {
	for i := range ab.Samples {
		ab.Samples[i] *= Sample(gain)
		if ab.Samples[i] > 1.0 {
			ab.Samples[i] = 1.0
		} else if ab.Samples[i] < -1.0 {
			ab.Samples[i] = -1.0
		}
	}
}

func (ab *AudioBuffer) Fade(fadeIn, fadeOut float64) {
	fadeInSamples := int(fadeIn * float64(ab.SampleRate))
	fadeOutSamples := int(fadeOut * float64(ab.SampleRate))
	totalSamples := len(ab.Samples)

	for i := 0; i < fadeInSamples && i < totalSamples; i++ {
		factor := float64(i) / float64(fadeInSamples)
		ab.Samples[i] *= Sample(factor)
	}

	for i := 0; i < fadeOutSamples && i < totalSamples; i++ {
		index := totalSamples - 1 - i
		factor := float64(i) / float64(fadeOutSamples)
		ab.Samples[index] *= Sample(factor)
	}
}

func (ab *AudioBuffer) Reverse() {
	for i, j := 0, len(ab.Samples)-1; i < j; i, j = i+1, j-1 {
		ab.Samples[i], ab.Samples[j] = ab.Samples[j], ab.Samples[i]
	}
}

func (ab *AudioBuffer) Mix(other *AudioBuffer, ratio float64) {
	length := len(ab.Samples)
	if len(other.Samples) < length {
		length = len(other.Samples)
	}

	for i := 0; i < length; i++ {
		ab.Samples[i] = ab.Samples[i]*(1-Sample(ratio)) + other.Samples[i]*Sample(ratio)
	}
}

type Oscillator struct {
	Phase      float64
	Frequency  float64
	SampleRate int
}

func NewOscillator(frequency float64, sampleRate int) *Oscillator {
	return &Oscillator{
		Phase:      0,
		Frequency:  frequency,
		SampleRate: sampleRate,
	}
}

func (o *Oscillator) NextSine() Sample {
	sample := math.Sin(2 * math.Pi * o.Phase)
	o.Phase += o.Frequency / float64(o.SampleRate)
	if o.Phase >= 1.0 {
		o.Phase -= 1.0
	}
	return Sample(sample)
}

func (o *Oscillator) NextSquare() Sample {
	sample := 1.0
	if o.Phase >= 0.5 {
		sample = -1.0
	}
	o.Phase += o.Frequency / float64(o.SampleRate)
	if o.Phase >= 1.0 {
		o.Phase -= 1.0
	}
	return Sample(sample)
}

func (o *Oscillator) NextSawtooth() Sample {
	sample := 2*o.Phase - 1
	o.Phase += o.Frequency / float64(o.SampleRate)
	if o.Phase >= 1.0 {
		o.Phase -= 1.0
	}
	return Sample(sample)
}

func (o *Oscillator) NextTriangle() Sample {
	sample := 0.0
	if o.Phase < 0.5 {
		sample = 4*o.Phase - 1
	} else {
		sample = -4*o.Phase + 3
	}
	o.Phase += o.Frequency / float64(o.SampleRate)
	if o.Phase >= 1.0 {
		o.Phase -= 1.0
	}
	return Sample(sample)
}

type Filter struct {
	a []float64
	b []float64
	x []Sample
	y []Sample
}

func NewLowPassFilter(cutoff float64, sampleRate int) *Filter {
	rc := 1.0 / (2.0 * math.Pi * cutoff)
	dt := 1.0 / float64(sampleRate)
	alpha := dt / (rc + dt)

	return &Filter{
		a: []float64{1.0 - alpha},
		b: []float64{alpha},
		x: make([]Sample, 1),
		y: make([]Sample, 1),
	}
}

func (f *Filter) Process(sample Sample) Sample {
	output := Sample(0)

	for i := range f.b {
		if i < len(f.x) {
			output += Sample(f.b[i]) * f.x[i]
		}
	}

	for i := range f.a {
		if i < len(f.y) {
			output += Sample(f.a[i]) * f.y[i]
		}
	}

	for i := len(f.x) - 1; i > 0; i-- {
		f.x[i] = f.x[i-1]
	}
	f.x[0] = sample

	for i := len(f.y) - 1; i > 0; i-- {
		f.y[i] = f.y[i-1]
	}
	f.y[0] = output

	return output
}

func (ab *AudioBuffer) ApplyFilter(filter *Filter) {
	for i := range ab.Samples {
		ab.Samples[i] = filter.Process(ab.Samples[i])
	}
}

func (ab *AudioBuffer) RMS() float64 {
	sum := 0.0
	for _, s := range ab.Samples {
		sum += float64(s * s)
	}
	return math.Sqrt(sum / float64(len(ab.Samples)))
}

func (ab *AudioBuffer) Peak() Sample {
	max := Sample(0)
	for _, s := range ab.Samples {
		if math.Abs(float64(s)) > float64(max) {
			max = Sample(math.Abs(float64(s)))
		}
	}
	return max
}
