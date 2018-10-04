;;;;;;;;;;;;;;;;;;;;;;;
;;;                 ;;;
;;;   METASPRITES   ;;;
;;;                 ;;;
;;;;;;;;;;;;;;;;;;;;;;;

Ok, first things first. We're going to want to declare some more constants to help 
make things easier to read for both you and anyone else who looks at your code.
Make at least one for your spriteRAM ($0300) or one for the ball
and one for each paddle like so:

BALL    = $0300 ; Assuming our first spriteRAM location is the ball and it uses only one sprite
PADDLE1 = $0304 ; Assuming our paddles are 4 sprites tall and starts with the second spriteRAM location
PADDLE2 = $0314 ; Our second paddle would start at the 6th spriteRAM location

Also we need to create a collisionDetected flag and bounding box sides in our variables section.

hitDetected     .rs 1

ballTOP         .rs 1
ballBOTTOM      .rs 1
ballLEFT        .rs 1
ballRIGHT       .rs 1
; 
; Do the same for each paddle TOP, BOTTOM, LEFT and RIGHT
;

We can now reference BALL, PADDLE1, and PADDLE2 in your code instead of using arbitrary addresses.
BALL, BALL+1, BALL+2, and BALL+3 access the four bytes associated with BALL ($0300 - $0303).
Same goes for PADDLE1, PADDLE1+1, PADDLE1+2, etc...

This is also useful for defining metasprites as we can move all sprites for a character in one fell swoop.

Example, our paddles:

updatePaddle1Location:
    LDA paddle1Y
    STA PADDLE1     ; Store paddle1Y in PADDLE1
    CLC
    ADC #$08        ; Add #$08
    STA PADDLE1+4   ;   and store in the first byte of the second sprite
    CLC
    ADC #$08
    STA PADDLE1+8   ; Repeat
    CLC
    ADC #$08
    STA PADDLE1+12  ; Repeat

    LDA paddle1X    ; Our paddle doesn't move left or right so all X values are the same
    STA PADDLE1+3
    STA PADDLE1+7
    STA PADDLE1+11
    STA PADDLE1+15
updatePaddle1LocationDone:
    RTS

Now in our main function we can JSR updatePaddle1Location and it will be updated each frame.
It would be even better to call this only when the paddles have moved.

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                    ;;;
;;;   BOUNDING BOXES   ;;;
;;;                    ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

Now for the bounding box business. Imagine that our character, in this case a ball, has a box around it that you want to check against 
another bounding box around a different set of sprites. We will need 4 variables that contain the top, bottom, left, and right sides 
of the box. To do this we can use our BALL constant to make a subroutine that calculates the bounding box. Alternatively we can use  
the X and Y position variables for each metasprite. ballX and ballY for example.

updateBallCollision:
    LDA BALL        ; Load BALL+0 which contains the Y coordinates of our ball
    STA ballTOP     ; Store in ballTOP. This is the top of our bounding box.
    CLC
    ADC #$07        ; Add #$07 to the Y coordinates to get the bottom of the ball
    STA ballBOTTOM  ;   and store in ballBOT to define the bottom of the bounding box

    LDA BALL+3      ; Load BALL+3 which contains the X coordinates of our ball
    STA ballLEFT    ; Store in ballLEFT. This is the left side of our bounding box.
    CLC
    ADC #$07        ; Add #$07 to the X coordinates to get the right side of the ball
    STA ballRIGHT   ;   and store in ballRIGHT to define the right side of the bounding box.
updateBallCollisionDone:
    RTS             ; Return from subroutine

We will need to do the same for each of our paddles. Keep in mind that they are 4 sprites tall so instead of adding $07 to the Y coordinates
for each paddle we will add $1F. Once this is done we can begin checking for collision.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                         ;;;
;;;   COLLISION DETECTION   ;;;
;;;                         ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

To check for collision we need to test RIGHT against LEFT and BOTTOM against TOP.

checkCollisionPad1:
    LDA ballRIGHT       ; Here we're checking if the right side of the ball
    CMP paddleLEFT      ;   is past the left side of the paddle.
    BCC .noHit          ; If not then there was no collision

    LDA ballBOTTOM      ; Repeat for ball bottom VS paddle top
    CMP paddleTOP
    BCC .noHit

    LDA paddleRIGHT     ; Repeat for paddle right VS ball left
    CMP ballLEFT
    BCC .noHit

    lda paddleBOTTOM    ; Repeat for paddle top VS ball bottom
    CMP ballTOP
    BCC .noHit
.hit
    LDA #$01            ; If all conditions are satisfied then we have collision
    STA hitDetected     ; Set the hitDetected flag
    RTS
.noHit
    LDA #$00            ; If any conditions fail then we have no collision
    STA hitDetected     ; Clear the hitDetected flag
checkCollisionPad1Done:
    RTS

We will also need to do this for paddle2 with the appropriate changes.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                          ;;;
;;;   PROCESSING COLLISION   ;;;
;;;                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Now we need te do something when a hit is detected

changeDirection:
    LDA hitDetected
    BEQ changeDirectionDone ; If hitDetected is #$00 then skip changing directions

    ; We insert our direction changing code here

changeDirectionDone:
    RTS
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                    ;;;
;;;   ADD TO FOREVER   ;;;
;;;                    ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

So now we should be able to add the following to our Forever loop:

    JSR updateBallLocation      ; Update our metasprites
    JSR updatePaddle1Location   ; Alternatively, we could add this one to the subroutine that reads controller 1
    JSR updatePaddle2Location   ;   and this one to the subroutine that reads controller 2
                                ;   instead of adding them to Forever so that they only run 
                                ;   when the paddles actually move

    JSR checkPaddle1Collision   ; Check for collision with paddle1
    JSR changeDirection         ; Process the hitDetected flag for paddle1

    JSR checkPaddle2Collision   ; Check for collision with paddle2
    JSR changeDirection         ; Process the hitDetected flag for paddle2


And that's the basics of sprite on sprite collision detection. It's not exactly intuitive,
but once we understand what's going on we can use the same method to add enemies and items.

