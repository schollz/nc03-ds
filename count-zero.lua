-- count zero

local os_capture=function(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

function zero_crossings(fname)
  local dat_string=os_capture("sox "..fname.." -r 48000 -t f32 - remix 1 | od -An -f  -v --width=4")
  local neg_to_pos={}
  local last_negative=false
  local sample=-1
  for word in dat_string:gmatch("%S+") do
    sample=sample+1
    local v=tonumber(word)
    local positive=v>0
    if positive and last_negative then
      table.insert(neg_to_pos,sample)
    end
    last_negative=not positive
  end
  return neg_to_pos
end

function reflect(fname,s1,s2)
  local crosses=zero_crossings(fname)
  local pos={{1,1},{1,1}}
  for i,sample in ipairs(crosses) do
    if sample<s1 then
      pos[1]={sample=sample,cross=i}
    end
    if sample<s2 then
      pos[2]={sample=sample,cross=i}
    end
  end
  local cmd=string.format("sox %s 1.wav remix 1 trim %ds %ds",fname,pos[1].sample,pos[2].sample-pos[1].sample)
  print(cmd)
  os_capture(cmd)

  cmd="sox -v -1 1.wav 2.wav reverse"
  print(cmd)
  os_capture(cmd)

  cmd="sox 1.wav 2.wav "..fname..".wav"
  print(cmd)
  os_capture(cmd)

  crosses=zero_crossings(fname..".wav")
  file=io.open(fname..".crossings","w")
  io.output(file)
  for i,sample in ipairs(crosses) do
    io.write(string.format("%d\n",sample))
  end
  io.close(file)
end

function setup()
  reflect(_path.audio.."nc03-ds/01-bd/01-bd_default-2.flac",1349,47963,25)
  reflect(_path.audio.."nc03-ds/01-bd/01-bd_verb-long.flac",3000,48000,25)
  reflect(_path.audio.."nc03-ds/03-tm/03-tm_verb-long.flac",11000,104835,35)
  reflect(_path.audio.."nc03-ds/04-cp/04-cp_verb-long.flac",8337,44603,35)
  reflect(_path.audio.."nc03-ds/06-cb/06-cb_verb-short.flac",2258,50920,75)
  reflect(_path.audio.."nc03-ds/07-hh/07-hh_verb-long.flac",3000,105000,65)
  reflect(_path.audio.."nc03-ds/02-sd/02-sd_verb-short.flac",14059,200000,88)
end

sc_prm=include 'lib/sc_params' -- param-based controls over softcut
sc_fn=include 'lib/sc_helpers' -- helper functions for different softcut actions, used by 'sc_params'
lfo=require 'lfo' -- parameter-based lfo library
s=require 'sequins'

sc_fn.play_slice=function(voice,slice)
  if samples[voice] and samples[voice].sample_count>0 then
    slice=util.wrap(slice,1,samples[voice].sample_count)
    samples[voice].current=slice
    softcut.rate(voice,sc_fn.get_total_pitch_offset(voice,samples[voice].mode))
    local target=samples[voice].mode=='file' and samples[voice] or samples[voice][slice]
    softcut.loop(voice,1)
    softcut.loop_start(voice,target.start_point)
    softcut.loop_end(voice,target.end_point)
    local pos;
    if samples[voice].changed_direction then
      pos=samples[voice].reversed and target.end_point-0.001 or target.start_point+0.001
    else
      pos=samples[voice].reversed and target.end_point or target.start_point
    end
    softcut.position(voice,pos)
  end
end

function init()
  -- initialize our softcut parameters:
  sc_prm.init()

  if not util.file_exists(_path.audio.."nc03-ds/01-bd/01-bd_default-2.flac.wav") then
    setup()
  end

  params:set("voice 1 sample",_path.audio.."nc03-ds/01-bd/01-bd_default-2.flac.wav")

end

function redraw()
  screen.clear()

  screen.update()
end
