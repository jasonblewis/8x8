/* -*- mode: c; -*- */ 
/*
2009 - robert:aT:spitzenpfeil_d*t:org - V3_x board test - V5
*/

#define __spi_clock 13   // SCK - hardware SPI
#define __spi_data_in 12 // MISO - hardware SPI (unused)
#define __spi_data 11    // MOSI - hardware SPI
#define __spi_latch 10
#define __LATCH_LOW PORTB &= ~(1 << PB2) // PB2 = Arduino Diecimila pin 10
#define __LATCH_HIGH PORTB |= (1 << PB2) // PB2 = Arduino Diecimila pin 10

#define __display_enable 9
#define __DISPLAY_ON PORTB &= ~(1 << PB1) // PB1 = Arduino Diecimila pin 9
#define __DISPLAY_OFF PORTB |= (1 << PB1) // PB1 = Arduino Diecimila pin 9

#define __rows 8
#define __max_row __rows-1
#define __leds_per_row 8
#define __max_led __leds_per_row-1
#define __brightness_levels 32 // higher numbers at your own risk ;-)
#define __max_brightness __brightness_levels-1
#define __red 0
#define __green 1
#define __blue 2
#define __led_colours 3

#define __TIMER1_MAX 0xFFFF // 16 bit counter
#define __TIMER1_CNT 0x0022 // 32 levels --> 0x0022

#define __led_pin 4
#define __button_pin 8
#define PRESSED LOW

#include <avr/interrupt.h>   
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <stdint.h>

struct t_pixel {
  byte red;
  byte green;
  byte blue;
};

typedef byte t_buffer[__rows][__leds_per_row];

t_buffer bufferA;
t_buffer bufferB;



byte brightness_red[__rows][__leds_per_row];	/* memory for RED LEDs - valid values: 0 - __max_brightness*/
byte brightness_green[__rows][__leds_per_row];	/* memory for GREEN LEDs */
byte brightness_blue[__rows][__leds_per_row]; 	/* memory for BLUE LEDs */





#define YES 1
#define NO 0
#define DOTCORR NO/* enable/disable dot correction */

#if (DOTCORR == YES)
const int8_t PROGMEM dotcorr_red[__rows][__leds_per_row] = { {0,0,0,0,0,0,0,0}, \
                                                             {0,0,0,0,0,0,0,0}, \
                                                             {0,0,0,0,0,0,0,0}, \
                                                             {0,0,0,0,0,0,0,0}, \
                                                             {0,0,0,0,0,0,0,0}, \
                                                             {0,0,0,0,0,0,0,0}, \
                                                             {0,0,0,0,0,0,0,0}, \
                                                             {0,0,0,0,0,0,0,0}  
                                                           };

const int8_t PROGMEM dotcorr_green[__rows][__leds_per_row] = { {0,0,0,0,0,0,0,0}, \
                                                               {0,0,0,0,0,0,0,0}, \
                                                               {0,0,0,0,0,0,0,0}, \
                                                               {0,0,0,0,0,0,0,0}, \
                                                               {0,0,0,0,0,0,0,0}, \
                                                               {0,0,0,0,0,0,0,0}, \
                                                               {0,0,0,0,0,0,0,0}, \
                                                               {0,0,0,0,0,0,0,0}  
                                                             };

const int8_t PROGMEM dotcorr_blue[__rows][__leds_per_row] = { {0,0,0,0,0,0,0,0}, \
                                                              {0,0,0,0,0,0,0,0}, \
                                                              {0,0,0,0,0,0,0,0}, \
                                                              {0,0,0,0,0,0,0,0}, \
                                                              {0,0,0,0,0,0,0,0}, \
                                                              {0,0,0,0,0,0,0,0}, \
                                                              {0,0,0,0,0,0,0,0}, \
                                                              {0,0,0,0,0,0,0,0}  
                                                            };
  #define __fade_delay 0                                                            
#else
  #define __fade_delay 4
#endif                                                         





void setup(void) {
  randomSeed(555);
  pinMode(__spi_clock,OUTPUT);
  pinMode(__spi_latch,OUTPUT);
  pinMode(__spi_data,OUTPUT);
  pinMode(__spi_data_in,INPUT);
  pinMode(__display_enable,OUTPUT);
  pinMode(__button_pin,INPUT);
  digitalWrite(__button_pin,HIGH);		/* turn on pullup */
  pinMode(__led_pin,OUTPUT);
  digitalWrite(__spi_latch,LOW);
  digitalWrite(__spi_data,LOW);
  digitalWrite(__spi_clock,LOW);
  setup_hardware_spi();
  delay(10);
  set_matrix_rgb(0,0,0);			/* set the display to BLACK */
  setup_timer1_ovf();				/* enable the framebuffer display */
  Serial.begin(9600);
}

void loop(void) {

demo();
//demo_2();
//demo_3();
  
}




/*
other functions
*/

void blink_led(byte times, byte wait) {
  byte ctr;
  for (ctr = 0; ctr < times; ctr++) {
    digitalWrite(__led_pin,HIGH);
    delay(wait);
    digitalWrite(__led_pin,LOW);
    delay(wait);
  }
}

void random_leds(void) {
  set_led_hue((byte)(random(__rows)),(byte)(random(__leds_per_row)),(int)(random(360)));
}

void smile_on(int hue) {					/* smily with open eyes */
  set_row_byte_hue(0,B00000000,hue);
  set_row_byte_hue(1,B01100110,hue);
  set_row_byte_hue(2,B01100110,hue);
  set_row_byte_hue(3,B00000000,hue);
  set_row_byte_hue(4,B00011000,hue);
  set_row_byte_hue(5,B10011001,hue);
  set_row_byte_hue(6,B01000010,hue);
  set_row_byte_hue(7,B00111100,hue);
}

void smile_off(int hue) {					/* smily with closed eyes */
  set_row_byte_hue(0,B00000000,hue);
  set_row_byte_hue(1,B00000000,hue);
  set_row_byte_hue(2,B01100110,hue);
  set_row_byte_hue(3,B00000000,hue);
  set_row_byte_hue(4,B00011000,hue);
  set_row_byte_hue(5,B10011001,hue);
  set_row_byte_hue(6,B01000010,hue);
  set_row_byte_hue(7,B00111100,hue);
}

void smile_blink(int hue, byte times, int pause) {		/* blink a smily */
 byte ctr;
 for(ctr = 0; ctr < times; ctr++) {
   delay(pause);
   smile_on(hue);
   delay(pause);
   smile_off(hue);
   delay(pause);
   smile_on(hue);
 }
}

void fader(void) {						/* fade the matrix form BLACK to WHITE and back */
  byte ctr1;
  byte row;
  byte led;

  for(ctr1 = 0; ctr1 <= __max_brightness; ctr1++) {
    for(row = 0; row <= __max_row; row++) {
      for(led = 0; led <= __max_led; led++) {
        set_led_rgb(row,led,ctr1,ctr1,ctr1);
      }
    }
    delay(__fade_delay);
  }
  
  for(ctr1 = __max_brightness; (ctr1 >= 0) & (ctr1 != 255); ctr1--) {
    for(row = 0; row <= __max_row; row++) {
      for(led = 0; led <= __max_led; led++) {
        set_led_rgb(row,led,ctr1,ctr1,ctr1);
      }
    }
    delay(__fade_delay);
  }
}

void fader_hue(void) {						/* cycle the color of the whole matrix */
  int ctr1;
  for(ctr1 = 0; ctr1 < 360; ctr1=ctr1+3) {
    set_matrix_hue(ctr1);
    delay(__fade_delay);
  }
}

void colors(void) {						/* some diagonal color pattern */
  int ctr1;
  int ctr2;
  byte row;
  byte led;
  byte tmp1;
  byte tmp2;
  byte tmp2_limit = 16;
  for(row = 0; row <= __max_row; row++) {
    for(led = 0; led <= __max_led; led++) {
      tmp1 = (led+1)*(row+1)/2;
      if(tmp1 <= tmp2_limit) { tmp2 = tmp1; } else { tmp2 = tmp2_limit; }
      set_led_rgb(row,led,(led+1)*(row+1)/2,tmp2_limit-tmp2,0);
    }
  }
}




/*
basic functions to set the LEDs
*/

//void set_led_RGB(t_buffer buffer, byte row, byte led, t_pixel pixel) {


void set_led_red(t_buffer buffer, byte row, byte led, byte red) {
  #if (DOTCORR == YES)
    int8_t dotcorr = (int8_t)(pgm_read_byte( &dotcorr_red[row][led] )) * red/__brightness_levels;
    uint8_t value;
    if( red + dotcorr < 0 ) {
      value = 0;
    }
    else {
      value = red + dotcorr;
    }
    brightness_red[row][led] = value;
  #else
    buffer[row][led].red = red;
  #endif
}

void set_led_green(t_buffer buffer, byte row, byte led, byte green) {
  #if (DOTCORR == YES)
    int8_t dotcorr = (int8_t)(pgm_read_byte( &dotcorr_green[row][led] )) * green/__brightness_levels;
    uint8_t value;
    if( green + dotcorr < 0 ) {
      value = 0;
    }
    else {
      value = green + dotcorr;
    }
    brightness_green[row][led] = value;
  #else
    buffer[row][led].green = green;
  #endif
}

void set_led_blue(t_buffer buffer, byte row, byte led, byte blue) {
  #if (DOTCORR == YES)
    int8_t dotcorr = (int8_t)(pgm_read_byte( &dotcorr_blue[row][led] )) * blue/__brightness_levels;
    uint8_t value;
    if( blue + dotcorr < 0 ) {
      value = 0;
    }
    else {
      value = blue + dotcorr;
    }
    brightness_blue[row][led] = value;
  #else
    buffer[row][led].blue = blue;
  #endif
}

void set_led_rgb(t_buffer buffer, byte row, byte led, t_pixel pixel ) {
  set_led_red(buffer,row,led,pixel.red);
  set_led_green(buffer,row,led,pixel.green);
  set_led_blue(buffer,row,led,pixel.blue);
}

void set_matrix_rgb(t_buffer buffer, t_pixel colour) {
  byte ctr1;
  byte ctr2;
  for(ctr2 = 0; ctr2 <= __max_row; ctr2++) {
    for(ctr1 = 0; ctr1 <= __max_led; ctr1++) {
      set_led_rgb(buffer,ctr2,ctr1,colour);
    }
  }
}

void set_row_rgb(t_buffer buffer, byte row, t_pixel colour) {
  byte ctr1;
  for(ctr1 = 0; ctr1 <= __max_led; ctr1++) {
    set_led_rgb(buffer,row,ctr1,colour);
  }
}

void set_column_rgb(t_buffer buffer, byte column, t_pixel colour) {
  byte ctr1;
  for(ctr1 = 0; ctr1 <= __max_row; ctr1++) {
    set_led_rgb(buffer,ctr1,column,colour);
  }
}

void set_row_hue(t_buffer buffer, byte row, int hue) {
  byte ctr1;
  for(ctr1 = 0; ctr1 <= __max_led; ctr1++) {
    set_led_hue(buffer,row,ctr1,hue);
  }
}

void set_column_hue(t_buffer buffer, byte column, int hue) {
  byte ctr1;
  for(ctr1 = 0; ctr1 <= __max_row; ctr1++) {
    set_led_hue(buffer,ctr1,column,hue);
  }
}

void set_matrix_hue(t_buffer buffer, int hue) {
  byte ctr1;
  byte ctr2;
  for(ctr2 = 0; ctr2 <= __max_row; ctr2++) {
    for(ctr1 = 0; ctr1 <= __max_led; ctr1++) {
      set_led_hue(buffer,ctr2,ctr1,hue);
    }
  }
}

void set_led_hue(t_buffer buffer, byte row, byte led, int hue) {
  // see wikipeda: HSV
  float S=100.0,V=100.0,s=S/100.0,v=V/100.0,h_i,f,p,q,t,R,G,B;
  t_pixel pixel;
    
    hue = hue%360;
    h_i = hue/60;            
    f = (float)(hue)/60.0 - h_i;
    p = v*(1-s);
    q = v*(1-s*f);
    t = v*(1-s*(1-f));
    
    if      ( h_i == 0 ) { 
      R = v; 
      G = t; 
      B = p;
    }
    else if ( h_i == 1 ) { 
      R = q; 
      G = v; 
      B = p;
    }
    else if ( h_i == 2 ) { 
      R = p; 
      G = v; 
      B = t;
    }
    else if ( h_i == 3 ) { 
      R = p; 
      G = q; 
      B = v;
    }
    else if ( h_i == 4 ) { 
      R = t; 
      G = p; 
      B = v;
    }
    else                   { 
      R = v; 
      G = p; 
      B = q;
    }
    colour.red = byte(R*(float)(__max_brightness));
    colour.green = byte(G*(float)(__max_brightness));
    colour.blue = byte(B*(float)(__max_brightness));

    set_led_rgb(buffer,row,led,colour);
}

void set_row_byte_hue(t_buffer buffer, byte row, byte data_byte, int hue) {
  byte led;
  for(led = 0; led <= __max_led; led++) {
    if( (data_byte>>led)&(B00000001) ) {
      set_led_hue(buffer,row,led,hue);
    }
    else {
      set_led_rgb(buffer,row,led,0,0,0);
    }
  }
}




/* demo */
void demo(void) {
int ctr;
  for(ctr=0; ctr < 200; ctr++) { 
    random_leds();
    if(digitalRead(__button_pin) == PRESSED) {
      fader();
      blink_led(2,50);
      colors();
      Serial.println("button pressed!");
      delay(1500);
    }
    else {
       blink_led(1,10);
    }
  }
  smile_blink(200,8,100);
  delay(2500);
}

/* demo_2() */
void demo_2(void) {
byte counter1;
byte counter2;

for (counter1 = 0; counter1 <= 7; counter1++) {
  for (counter2 = 0; counter2 <= 7; counter2++) {
    set_led_rgb(bufferA,counter1,counter2,32,0,0);
    delay(10);
    set_led_rgb(bufferA,counter1,counter2,0,32,0);
    delay(10);
    set_led_rgb(bufferA,counter1,counter2,0,0,32);
    delay(10);
    set_led_rgb(bufferA,counter1,counter2,32,32,32);
    delay(10);
  }
}

//myfunct( (struct
//               somestruct){.a = 1, .b = 1, .c = 2} );
 set_matrix_rgb(bufferA,(struct t_pixel){.red=0,.green=0,.blue=0});

}

/* demo_3() */
void demo_3(void) {
static byte counter = 0;

if( digitalRead(__button_pin) == PRESSED ) {
  counter++;
}
if( counter > 4 ) {
  counter = 0;
}

switch( counter ) {
  case 0:
    set_matrix_rgb(5,0,0);
  break;
  case 1:
    set_matrix_rgb(0,5,0);  
  break;
  case 2:
      set_matrix_rgb(0,0,5);
  break;
  case 3:
      set_matrix_rgb(255,255,255);
  break;
  case 4:
    set_matrix_rgb(0,0,0);
  break;
  default:
  break; 
}

delay(250);

}




/*
Functions dealing with hardware specific jobs / settings
*/

void setup_hardware_spi(void) {
  byte clr;
  // spi prescaler: 
  // SPI2X SPR1 SPR0
  //   0     0     0    fosc/4
  //   0     0     1    fosc/16
  //   0     1     0    fosc/64
  //   0     1     1    fosc/128
  //   1     0     0    fosc/2
  //   1     0     1    fosc/8
  //   1     1     0    fosc/32
  //   1     1     1    fosc/64
  SPCR |= ( (1<<SPE) | (1<<MSTR) ); // enable SPI as master
  //SPCR |= ( (1<<SPR1) ); // set prescaler bits
  SPCR &= ~ ( (1<<SPR1) | (1<<SPR0) ); // clear prescaler bits
  clr=SPSR; // clear SPI status reg
  clr=SPDR; // clear SPI data reg
  SPSR |= (1<<SPI2X); // set prescaler bits
  //SPSR &= ~(1<<SPI2X); // clear prescaler bits
}

void setup_timer1_ovf(void) {
  // Arduino runs at 16 Mhz...
  // Timer1 (16bit) Settings:
  // prescaler (frequency divider) values:   CS12    CS11   CS10
  //                                           0       0      0    stopped
  //                                           0       0      1      /1  
  //                                           0       1      0      /8  
  //                                           0       1      1      /64
  //                                           1       0      0      /256 
  //                                           1       0      1      /1024
  //                                           1       1      0      external clock on T1 pin, falling edge
  //                                           1       1      1      external clock on T1 pin, rising edge
  //
  TCCR1B &= ~ ( (1<<CS11) );
  TCCR1B |= ( (1<<CS12) | (1<<CS10) );      
  //normal mode
  TCCR1B &= ~ ( (1<<WGM13) | (1<<WGM12) );
  TCCR1A &= ~ ( (1<<WGM11) | (1<<WGM10) );
  //Timer1 Overflow Interrupt Enable  
  TIMSK1 |= (1<<TOIE1);
  TCNT1 = __TIMER1_MAX - __TIMER1_CNT;
  // enable all interrupts
  sei(); 
}

ISR(TIMER1_OVF_vect) { /* Framebuffer interrupt routine */
  TCNT1 = __TIMER1_MAX - __TIMER1_CNT;
  uint8_t pwm_cycle;
  static uint8_t row = 0;
  
  __DISPLAY_ON;
  
    for(pwm_cycle=0; pwm_cycle <=__max_brightness; pwm_cycle++) {
  
      byte led;
      byte red = B11111111;		// off
      byte green = B11111111;           // off
      byte blue = B11111111;		// off
      
      for(led = 0; led <= __max_led; led++) {
        if(pwm_cycle < brightness_red[row][led]) {
          red &= ~(1<<led);
        }
        //else {
        //  red |= (1<<led);
        //}
          
        if(pwm_cycle < brightness_green[row][led]) {
          green &= ~(1<<led);
        }
        //else {
        //  green |= (1<<led);
        //}

        if(pwm_cycle < brightness_blue[row][led]) {
          blue &= ~(1<<led);
        }
        //else { 
        //  blue |= (1<<led);
        //}
      }

      __LATCH_LOW;
        spi_transfer(B00000001<<row);
        spi_transfer(blue);
        spi_transfer(green);
        spi_transfer(red);
      __LATCH_HIGH;

    }
    
  __DISPLAY_OFF;
  
  row++; // next time the ISR runs, the next row will be dealt with
  
  if(row > __max_row) {
    row = 0;
  }
  
}

byte spi_transfer(byte data) {
  SPDR = data;                    // Start the transmission
  while (!(SPSR & (1<<SPIF)))     // Wait the end of the transmission
  {
  };
  return SPDR;                    // return the received byte. (we don't need that here)
}
