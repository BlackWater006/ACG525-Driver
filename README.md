# FPGA Memory Game on Gowin GW5A-LV25UG / ACG525

## 1. Project Overview

This project implements a simple **Memory Game**, also known as a **Simon Says game**, on the **Gowin GW5A-LV25UG / ACG525 FPGA development board**. The game generates a random LED sequence, displays it to the player, and then requires the player to repeat the sequence correctly using onboard buttons.

The project was developed using **Verilog HDL** and synthesized with **Gowin EDA**. It uses onboard LEDs, push buttons, and a 7-segment display driven through a serial interface.

## 2. Main Features

* Generates a pseudo-random LED sequence using an LFSR module.
* Displays the pattern through onboard LEDs.
* Allows the player to input the sequence using push buttons.
* Uses debounce logic to make button input stable.
* Shows the current score on the 7-segment display.
* Displays `LOSER` when the player presses the wrong button.
* Displays `WINER` when the player completes the game.
* Uses a CST constraint file for pin mapping on the ACG525 board.

## 3. Hardware Used

* FPGA board: **Gowin GW5A-LV25UG / ACG525**
* Onboard clock: **50 MHz**
* Onboard LEDs
* Onboard push buttons
* Onboard 7-segment display module using 74HC595-style serial control

## 4. Gameplay Description

The game works as follows:

1. After reset, the FPGA generates a random sequence.
2. The LEDs show the sequence step by step.
3. The player watches and memorizes the sequence.
4. After the sequence is shown, the player presses the corresponding buttons.
5. If the player is correct, the score increases and the next round becomes longer.
6. If the player makes a mistake, the 7-segment display shows `LOSER`.
7. If the player reaches the final score, the 7-segment display shows `WINER`.

Button mapping:

| LED  | Button | Display Hint |
| ---- | ------ | ------------ |
| LED0 | KEY0   | 1            |
| LED1 | KEY1   | 2            |
| LED2 | KEY2   | 3            |

Since the board has only three onboard buttons available for gameplay, this version uses three playable inputs instead of four.

## 5. Project Structure

```text
MemoryGame/
├── src/
│   ├── MemoryGameTopLvl.v
│   ├── StateMachineGame.v
│   ├── DebounceFilter.v
│   ├── Lfsr22.v
│   ├── Seg7_595_WordDisplay.v
│   └── BinaryToSevSeg.v
├── constraints/
│   └── lab_6_fix.cst
├── timing/
│   └── timing.sdc
└── README.md
```

## 6. Module Description

### 6.1 `MemoryGameTopLvl.v`

This is the top-level module of the project. It connects all submodules together, including:

* Button debounce modules
* Game state machine
* 7-segment display driver
* LED outputs
* Clock input
* Button input

Main responsibilities:

* Receives clock and button signals.
* Debounces button inputs.
* Sends clean button signals to the game state machine.
* Sends game status and score to the 7-segment display module.

### 6.2 `StateMachineGame.v`

This is the main logic module of the game. It controls the whole game flow using a finite state machine.

Main states:

| State         | Description                            |
| ------------- | -------------------------------------- |
| `START`       | Reset score and generate a new pattern |
| `PATTERN_OFF` | Short delay between LED flashes        |
| `SHOW_STEP`   | Show each LED in the pattern           |
| `WAIT_PLAYER` | Wait for player input                  |
| `LOSE`        | Player pressed the wrong button        |
| `WIN`         | Player completed the game              |

The module outputs:

* LED pattern
* Current score
* Game status

Game status values:

```verilog
0 = normal gameplay
1 = lose
2 = win
```

### 6.3 `DebounceFilter.v`

Mechanical buttons can produce unstable signals when pressed or released. This module filters the input signal so that each button press is detected correctly.

Without debounce filtering, one press may be detected as multiple presses.

### 6.4 `Lfsr22.v`

This module generates pseudo-random data using a 22-bit Linear Feedback Shift Register.

The random data is used to create the LED sequence for the memory game.

### 6.5 `Seg7_595_WordDisplay.v`

This module controls the onboard 7-segment display through a serial interface.

It can display:

* Normal score during gameplay
* `LOSER` when the player loses
* `WINER` when the player wins

Because a 7-segment display cannot show all alphabet letters perfectly, some characters are approximated. For example, the letter `W` is displayed in a form similar to `U`.

### 6.6 `BinaryToSevSeg.v`

This module converts a 4-bit binary number into a 7-segment pattern.

It is mainly used for displaying numbers such as score values.

## 7. Pin Assignment

The project uses the following pin mapping for the ACG525 board.

| Signal        | Function              | FPGA Pin |
| ------------- | --------------------- | -------- |
| `i_clk`       | 50 MHz clock          | T9       |
| `i_sw[0]`     | KEY0                  | B16      |
| `i_sw[1]`     | KEY1                  | A15      |
| `i_sw[2]`     | KEY2                  | C15      |
| `i_sw[3]`     | External reset button | C17      |
| `o_led[0]`    | LED0                  | D14      |
| `o_led[1]`    | LED1                  | C14      |
| `o_led[2]`    | LED2                  | B9       |
| `o_led[3]`    | Status LED            | A9       |
| `o_seg7_dio`  | 7-segment serial data | F4       |
| `o_seg7_rclk` | 7-segment latch clock | F3       |
| `o_seg7_sclk` | 7-segment shift clock | H4       |

## 8. CST Constraint File

Example CST file:

```cst
IO_LOC  "i_clk" T9;
IO_PORT "i_clk" IO_TYPE=LVCMOS33;

IO_LOC  "i_sw[0]" B16;
IO_PORT "i_sw[0]" IO_TYPE=LVCMOS33 PULL_MODE=UP;

IO_LOC  "i_sw[1]" A15;
IO_PORT "i_sw[1]" IO_TYPE=LVCMOS33 PULL_MODE=UP;

IO_LOC  "i_sw[2]" C15;
IO_PORT "i_sw[2]" IO_TYPE=LVCMOS33 PULL_MODE=UP;

IO_LOC  "i_sw[3]" C17;
IO_PORT "i_sw[3]" IO_TYPE=LVCMOS33 PULL_MODE=UP;

IO_LOC  "o_led[0]" D14;
IO_PORT "o_led[0]" IO_TYPE=LVCMOS33;

IO_LOC  "o_led[1]" C14;
IO_PORT "o_led[1]" IO_TYPE=LVCMOS33;

IO_LOC  "o_led[2]" B9;
IO_PORT "o_led[2]" IO_TYPE=LVCMOS33;

IO_LOC  "o_led[3]" A9;
IO_PORT "o_led[3]" IO_TYPE=LVCMOS33;

IO_LOC  "o_seg7_dio" F4;
IO_PORT "o_seg7_dio" IO_TYPE=LVCMOS33;

IO_LOC  "o_seg7_rclk" F3;
IO_PORT "o_seg7_rclk" IO_TYPE=LVCMOS33;

IO_LOC  "o_seg7_sclk" H4;
IO_PORT "o_seg7_sclk" IO_TYPE=LVCMOS33;
```

## 9. Timing Constraint

The onboard clock is 50 MHz, so the clock period is 20 ns.

Example `timing.sdc`:

```sdc
create_clock -name i_clk -period 20.000 [get_ports {i_clk}]
```

## 10. How to Run the Project

1. Open Gowin EDA.
2. Create or open the project.
3. Add all Verilog source files.
4. Add the CST constraint file.
5. Add the SDC timing file.
6. Set the top module to:

```text
MemoryGameTopLvl
```

7. Run synthesis.
8. Run place and route.
9. Generate bitstream.
10. Program the FPGA board.

## 11. Testing Result

After programming the FPGA:

* The LEDs flash a pattern.
* The player repeats the pattern using KEY0, KEY1, and KEY2.
* The score is displayed on the 7-segment display.
* If the wrong button is pressed, the display shows `LOSER`.
* If the final level is completed, the display shows `WINER`.

## 12. Problems and Solutions

### Problem 1: 7-segment display showed wrong numbers

The first version assumed that the 7-segment display was directly connected with 7 segment pins. However, the ACG525 board uses a serial display interface. The solution was to create a new 7-segment driver module using serial data, shift clock, and latch clock.

### Problem 2: Game always showed `F`

The original game logic was designed for four buttons, but the board only had three onboard buttons available for gameplay. The random pattern was changed to use only three button values.

### Problem 3: Text appeared reversed on the 7-segment display

The digit mapping was reversed. The display driver was modified so that words appear from left to right.

### Problem 4: OLED onboard was difficult to control

The onboard OLED uses special-purpose pins that may be locked by default in Gowin. Because of this, the final version focuses on displaying `LOSER` and `WINER` on the 7-segment display instead of the OLED.

## 13. Future Improvements

Possible improvements include:

* Add support for four gameplay buttons using external GPIO buttons.
* Add sound feedback using the onboard buzzer.
* Add difficulty levels.
* Add a countdown timer.
* Improve the 7-segment font for letters.
* Add OLED display support if the dual-purpose pins are configured correctly.
* Store the highest score using external memory.

## 14. Conclusion

This project demonstrates how to build a memory game using Verilog HDL on a Gowin FPGA board. It combines several important digital design concepts, including finite state machines, button debouncing, pseudo-random sequence generation, clock-based timing, GPIO constraints, and serial display control.

Through this project, I learned how to connect multiple Verilog modules together, debug pin constraint issues, adapt a design to real FPGA hardware, and display both numbers and text on a 7-segment display.

