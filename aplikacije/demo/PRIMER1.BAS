rem RAF_OS BASIC Demo program 1
rem ---------------------------

cls

print "Kako se zoves? " ;      rem Tacka-zarez znace da se ne ispisuje novi red
input $1
print "Zdravo " ;              
print $1                       rem Ovaj BASIC razlikuje mala i velika slova
print "Koliko su 2 i 2? "      rem kod string promenljivih
waitkey x

if $1 = "Stevan" then goto uvek_OK
if x = '4' then goto tacan
print "Ne, 2 i 2 su 4."
end

tacan:
   print "Ne, 2 i 2 su 22."
end

uvek_OK:
   print "Stevane, za tebe je svaki odgovor tacan!"
end 

