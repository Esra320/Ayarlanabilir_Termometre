'****************************************************************
'*  Name    : TERMOMETRE.BAS                                    *
'*  Author  : [Esra YÜCE]                                       *
'*  Notice  : DS18B20'li oda termometresi]                      *
'*          :                                                   *
'*  Date    : 20.05.2020                                        *
'*  Version :                                                   *
'*  Notes   : Isý sensörü olarak DS18B20 kullanýlacaktýr.       * 
'****************************************************************
DEFINE OSC 4

@ DEVICE pic16F628                      'iþlemci 16F628                               
@ DEVICE pic16F628, WDT_ON              'Watch Dog timer açýk
@ DEVICE pic16F628, PWRT_ON             'Power on timer açýk
@ DEVICE pic16F628, PROTECT_OFF         'Kod Protek kapalý
@ DEVICE pic16F628, MCLR_off            'MCLR pini kullanýlMIYOR.
@ DEVICE pic16F628, INTRC_OSC_NOCLKOUT  'Dahili osilatör kullanýlacak 

TRISA=%10111000
TRISB=%00000000
PORTA=0:PORTB=0

CMCON=7  'Comparatör pinleri iptal hepsi giriþ çýkýþ
ON INTERRUPT GoTo KESME   'kesme oluþursa KESME adlý etikete git.
'presc:000=1/2, 001=1/4, 010=1/8, 011=1/16, 100=1/32, 101=1/64, 110=1/128,111=1/256	
OPTION_REG=%00000011  'Pull up dirençleri ÝPTAL- Bölme oraný 1/16
INTCON=%10100000  'Kesmeler aktif ve TMR0 (bit5) kesmesi aktif
TMR0=99

'---------------------------PIN TANIMLAMALARI-----------------------------------
SYMBOL SET=PORTA.5
SYMBOL YUKARI=PORTA.4
SYMBOL ASAGI=PORTA.3
SYMBOL DIG0=PORTA.0
SYMBOL DIG1=PORTA.1
SYMBOL DIG2=PORTA.2
'-------------------------------------------------------------------------------
ROLE  VAR PORTA.6
'-----------------------------DEÐÝÞKENLER---------------------------------------

SAYAC  VAR  BYTE
SIRA   VAR  BYTE
SAYI   VAR  BYTE
TERM   VAR  WORD
ISIS   VAR  WORD
ONDA   VAR  BYTE
AKTAR1 VAR  BYTE
AKTAR2 VAR  BYTE
AKTAR3 VAR  BYTE
SYC    VAR  BYTE
SNS    VAR  BYTE
SNY    VAR  BYTE
ISIH   VAR  BYTE
ISIL   VAR  BYTE
TUS    VAR  BIT
DP     VAR  BIT
W      VAR  BIT
U      VAR  BIT
Z      VAR  BYTE
X      VAR  BYTE
I      VAR  WORD
'---------------------------------ISI TANIMLAMALARI-----------------------------
    Busy        VAR BIT         ' Busy Status-Bit
    HAM         VAR	WORD
    ISI         VAR WORD        ' Sensör HAM okuma deðeri
    Float       VAR WORD        ' Holds remainder for + temp C display       
    ISARET_BITI VAR HAM.11'Bit11   '   +/- sýcaklýk Ýþaret biti,  1 = olursa eksi sýcaklýk
    EKSI_ISI    CON 1           ' Negatif_Cold = 1
    SERECE      CON 223         ' ° iþareti
    ISARET      VAR BYTE        
    Comm_Pin    VAR	PORTA.7
'-------------------------------------------------------------- 

BASLANGIC:DP=0'--------------------BAÞLANGIC------------------------------------   
gosub EKRAN3
gosub SENSORYAZ
GOSUB SENSOROKU
read $0,ISIL
READ $1,ISIH
READ $2,SNS
IF ISIL>99 THEN ISIL=0
IF ISIH>9 THEN ISIH=0
IF SNS>50 THEN SNS=0
TERM=(ISIL*10)+ISIH
ISIS=TERM-SNS
GOSUB DELAY1
DP=1:W=1:SYC=0

BASLA:'----------------------------ANA DONGÜ------------------------------------
GOSUB EKRAN
GOSUB SENSOROKU
GOSUB KONTROL

IF TUS=1 THEN GOTO AYAR
GOTO BASLA

'--------------------------------ALT PROGRAMLAR---------------------------------

SENSOROKU:
           OWOUT   Comm_Pin, 1, [$CC, $44]' ISI deðerini oku
Bekle:
           OWIN    Comm_Pin, 4, [Busy]    ' Busy deðerini oku
           IF      Busy = 0 THEN Bekle    ' hala meþgulmü? , evet ise goto Bekle..!
           OWOUT   Comm_Pin, 1, [$CC, $BE]' scratchpad memory oku
           OWIN    Comm_Pin, 2, [HAM.Lowbyte, HAM.Highbyte]' Ýki byte oku ve okumayý bitir.
           GOSUB   Hesapla
           RETURN
SENSORYAZ: 'okumaya hazýrlan..          
OWOUT   Comm_Pin, 1, [$CC,$4E, $FF, $FF, $7F]
OWOUT   Comm_Pin, 1, [$CC,$48]          
OWOUT   Comm_Pin, 1, [$CC,$B8]          
OWOUT   Comm_Pin, 1, [$CC,$BE]          
return 

    
Hesapla:  ' Ham deðerden Santigrat derece hesabý
    ISARET  = "+"
    IF ISARET_BITI = EKSI_ISI THEN
       ISARET   = "-"  
       ham=~ham+2
    endif
    float = (HAM*10)/16  
    RETURN  
END
     
RETURN 

KONTROL: ' Role kontrol..
IF ISIS=>FLOAT THEN 
  SYC=SYC+1
   IF SYC=>3 THEN 
   SYC=3:HIGH ROLE
   ENDIF
endIF
IF FLOAT=>TERM THEN 
  SYC=0:LOW ROLE
ENDIF
RETURN   

DELAY: 'gecýkme 1
  FOR I=0 TO 150:NEXT
RETURN
DELAY1:'gecýkme 2
  FOR I=0 TO 12000:NEXT
RETURN
DELAY2:'gecýkme 3
  FOR I=0 TO 125:NEXT
RETURN

EKRAN:'Sýcaklýk gösteriliyor.
 Z=FLOAT DIG 0:GOSUB AL:AKTAR1=SAYI          
 Z=FLOAT DIG 1:GOSUB AL:AKTAR2=SAYI
 Z=FLOAT DIG 2:GOSUB AL:AKTAR3=SAYI
RETURN
EKRAN1: 'SET yazýsý
 Z=14:GOSUB AL:AKTAR1=SAYI
 Z=13:GOSUB AL:AKTAR2=SAYI
 Z=5:GOSUB AL:AKTAR3=SAYI
RETURN
EKRAN2:'Set deðeri gösteriliyor
 Z=TERM DIG 0:GOSUB AL:AKTAR1=SAYI:IF U=1 THEN AKTAR1=0
 Z=TERM DIG 1:GOSUB AL:AKTAR2=SAYI
 Z=TERM DIG 2:GOSUB AL:AKTAR3=SAYI
RETURN
EKRAN3:
 AKTAR1=64
 AKTAR2=64
 AKTAR3=64
RETURN
EKRAN4:'Hassasiyet ekraný
 Z=SNS DIG 0:GOSUB AL:AKTAR1=SAYI:IF U=1 THEN AKTAR1=0
 Z=SNS DIG 1:GOSUB AL:AKTAR2=SAYI
 aktar3=0
RETURN
 
AL: LOOKUP Z,[63,6,91,79,102,109,125,7,127,111,99,57,64,121,120],SAYI :RETURN'Karakter al 

KAYDET: 'Deðerler eproom'a kaydediliyor..
WHILE TUS=1:WEND
 ISIL=TERM/10
 ISIH=TERM//10
 WRITE $0,ISIL:PAUSEUS 2
 WRITE $1,ISIH:PAUSEUS 2
 WRITE $2,SNS:PAUSEUS 2
GOTO BASLANGIC

AYAR: 'Menuye gýrýs 
 WHILE TUS=1:WEND
 DP=0 
 GOSUB EKRAN1
 GOSUB DELAY1
 READ $0,ISIL
 READ $1,ISIH
 TERM=(ISIL*10)+ISIH
 DP=1:syc=0:SNY=0:W=0 

MENU:
IF YUKARI=0 THEN
W=1:U=0:sny=0 
TERM=TERM+1
 WHILE YUKARI=0
   SYC=SYC+1:GOSUB DELAY
     IF SYC>40 THEN
       SYC=50:TERM=TERM+1:GOSUB DELAY
     ENDIF 
   GOSUB EKRAN2
   IF TERM>990 THEN TERM=0
 WEND
 SYC=0:IF TERM>999 THEN TERM=990
ELSE
W=0
ENDIF

IF ASAGI=0 THEN
W=1:U=0:sny=0  
TERM=TERM-1
 WHILE ASAGI=0
   SYC=SYC+1:GOSUB DELAY
     IF SYC>40 THEN
       SYC=50:TERM=TERM-1:GOSUB DELAY
     ENDIF 
   GOSUB EKRAN2
   IF TERM>999 THEN TERM=990
 WEND
 SYC=0:IF TERM>999 THEN TERM=990
ELSE
W=0
ENDIF

IF TUS=1 THEN
GOTO SENSIVITY
ENDIF
GOSUB EKRAN2
GOTO MENU

SENSIVITY: '| menusu giriþ..
WHILE TUS=1:WEND
read $2,sns
IF SNS>50 THEN SNS=0
DP=1:SNY=0
SENS:
GOSUB EKRAN4
IF YUKARI=0 THEN
W=1:SNY=0:U=0  
SNS=SNS+1
 WHILE YUKARI=0
   SYC=SYC+1:GOSUB DELAY
     IF SYC>40 THEN
       SYC=40:SNS=SNS+1:GOSUB DELAY2
     ENDIF 
   GOSUB EKRAN4
   IF SNS=>50 THEN SNS=50
 WEND
 SYC=0:IF SNS=>50 THEN SNS=50
ELSE
W=0
ENDIF            

IF ASAGI=0 THEN
 W=1:U=0:sny=0 
 SNS=SNS-1
 WHILE ASAGI=0
   SYC=SYC+1:GOSUB DELAY
     IF SYC>40 THEN
       SYC=40:SNS=SNS-1:GOSUB DELAY2
     ENDIF 
   GOSUB EKRAN4
   IF SNS>50 THEN SNS=0
 WEND
 SYC=0:IF SNS>50 THEN SNS=0
ELSE
W=0
ENDIF

IF TUS=1 THEN 
GOTO KAYDET
ENDIF
GOTO SENS

Disable         		
KESME:  'kesme alt programý
  IF SET=0 THEN 
  TUS=1
  ELSE
  TUS=0
  ENDIF
  
IF W=0 THEN 
  SNY=SNY+1
  IF SNY=>120 THEN 
    U=1
    ELSE
    U=0
  ENDIF
ENDIF
IF SNY=>240 THEN SNY=0

	SAYAC=SAYAC+1				
   	If SAYAC>2 then SAYAC=0	

    If SAYAC=0 then
	  DIG2=0 
	  PORTB=AKTAR1
	  DIG0=1  
      PAUSEUS 2   	
	  Endif

	  If SAYAC=1 then		
	  DIG0=0
	  PORTB=AKTAR2
	  PORTB.7=DP
	  DIG1=1 
	  PAUSEUS 2
	  Endif
	  
	  If SAYAC=2 then		
	  DIG1=0
	  PORTB=AKTAR3
	  DIG2=1 
	  PAUSEUS 2
	  Endif	
          
   	TMR0=160
    INTCON.2=0
    			
    Resume		
	Enable	
  end		      






