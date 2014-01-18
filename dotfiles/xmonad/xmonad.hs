import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Layout.MouseResizableTile
import XMonad.Prompt
import XMonad.Prompt.Window
import XMonad.Prompt.RunOrRaise
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO

import Data.Char (toLower)
import Data.List (isInfixOf)
import Data.List.Split (splitOn)

myModMask :: KeyMask
myModMask = mod4Mask

main = do
    xmproc <- spawnPipe "/usr/bin/xmobar /home/tom/.xmobarrc"

    xmonad $ defaultConfig
        { manageHook = manageDocks <+> manageHook defaultConfig
        , terminal   = "emacsclient -c --eval '(eshell \"foo\")'"
        , layoutHook = avoidStruts $ (mouseResizableTile ||| layoutHook defaultConfig)
        , logHook = dynamicLogWithPP xmobarPP
                        { ppOutput = hPutStrLn xmproc
                        , ppTitle = xmobarColor "green" "" . shorten 50
                        }
        , modMask = myModMask
        }
        `additionalKeys`
        [ ((myModMask .|. shiftMask, xK_g), windowPromptGoto myXPConfig)
        , ((myModMask .|. shiftMask, xK_b), windowPromptBring myXPConfig)
        , ((myModMask .|. shiftMask, xK_x), runOrRaisePrompt myXPConfig)
        ]

myXPConfig :: XPConfig
myXPConfig = greenXPConfig
    { autoComplete = Nothing
    , font = "-misc-fixed-*-*-*-*-20-*-*-*-*-*-*-*"
    , searchPredicate = orderIndepdentSubstringMatcher
    }


-- orderIndepdentSubstringMatcher "fire trel" "trello - Firefox" -> True
-- Terrible name. Shut up, naming is hard.
orderIndepdentSubstringMatcher :: String -> String -> Bool
orderIndepdentSubstringMatcher inputString windowTitle = all (\word -> word `matchesAtLeastOneWordOf` windowTitle) $ split inputString
    where
        word `matchesAtLeastOneWordOf` window = any (isInfixOf word) (split window)
        split :: String -> [String]
        split s = splitOn " " $ map toLower s
