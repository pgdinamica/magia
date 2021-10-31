using VideoIO
using ProgressMeter
using Images, LocalFilters
using LinearAlgebra


# Fiz minha Capa da Invisibilidade | Tecnologia ou Magia #1
# Assista ao vídeo:
function processframe(rgb_img, settings, background)
    hsv_img = HSV.(rgb_img)
    # separa os canais
    channels = channelview(float.(hsv_img))
    hue_img = channels[1,:,:]
    saturation_img = channels[2,:,:]
    value_img = channels[3,:,:]

    # máscara binária
    mask = zeros(size(hue_img))
    for ind in eachindex(hue_img)
        if ((settings[:minhue] ≤ hue_img[ind] ≤ settings[:maxhue])
            && (settings[:minsat] ≤ saturation_img[ind] ≤ settings[:maxsat])
            && (settings[:minval] ≤ value_img[ind] ≤ settings[:maxval]))
            mask[ind] = 1
        end
    end

    # pós processamento (operações morfológicas)
    morphed = LocalFilters.opening(mask, 42)
    morphed = LocalFilters.closing(morphed, 42)
    morphed = LocalFilters.dilate(morphed, 15)

    back = morphed .* background
	front = (1 .- morphed) .* rgb_img
    # converte da representação em float para inteiros de 8 bits por canal
	RGB{N0f8}.(back + front)
end

# Configure os caminhos na sua máquina
BACKGROUND_PATH = ""
IMG_DIR = "img"
VIDEO_DIR = "videos"
OUT_DIR = "output"
inputfile = ""

cloaksettings = Dict(
    :minhue => 202,
    :maxhue => 250,
    :minsat => 0.30,
    :maxsat => 1.0,
    :minval => 0.02,
    :maxval => 1.0
)

encoder_options = (crf=14, preset="medium")
framerate = 30

framestack =  openvideo(joinpath(VIDEO_DIR, inputfile))
firstframe = read(framestack)
background = if isempty(BACKGROUND_PATH)
                firstframe
            else
                load(BACKGROUND_PATH)
            end
frame = processframe(firstframe, cloaksettings, background)

open_video_out(joinpath(OUT_DIR, "cloak-$inputfile"), firstframe, framerate=framerate, encoder_options=encoder_options) do writer
    
    prog = ProgressUnknown("Processando vídeo:", spinner=true)
    for frame in framestack
        write(writer, processframe(frame, cloaksettings, background))
        ProgressMeter.next!(prog, spinner="🌑🌒🌓🌔🌕🌖🌗🌘")
    end
    ProgressMeter.finish!(prog)
end

print("Vídeo finalizado!")