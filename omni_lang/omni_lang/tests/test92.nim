def something:
  loop:
    a = 20
    loop:
      b = 300
      c = 30

init:
  loop:
    a = 20
    loop:
      b = 300
      c = 30
  
  something()

sample: something()
