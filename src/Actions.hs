module Actions (
    jump
  , frame
  , restart
) where

import ClassyPrelude

import Control.Lens ((&), (^.), (.~), (%~), (+~))
import Types (Player, Direction(..), UI, Direction(..), State(..), Obstacles, reset, player, position, obstacles, state, speed, dimensions)
import Loop (fps)

restart :: UI -> UI
restart ui = case ui ^. state of
    GameOver -> Types.reset ui
    _ -> ui

jump :: UI -> UI
jump ui = case ui ^. state of
    Playing -> ui & player %~ startJump
    _ -> ui

frame :: Int -> UI -> UI
frame rand ui = case ui ^. state of
    Playing -> nextFrame rand ui
    _ -> ui

-- internal functions
nextFrame :: Int -> UI -> UI
nextFrame rand ui = ui
    & state .~ st
    & player %~ animate
    & position +~ distance
    & obstacles %~ generateObstacles rand ui

    where gameOver = collision ui
          distance = if gameOver then 0 else 1 / fromIntegral fps * fromIntegral (ui ^. speed)
          st = if gameOver then GameOver else Playing

generateObstacles :: Int -> UI -> Obstacles -> Obstacles
generateObstacles rand ui obs = if shouldAppend then filtered ++ [final + rand] else filtered
    where pos = floor $ ui ^. position
          (w, _) = ui ^. dimensions
          final = fromMaybe 0 $ lastMay obs
          shouldAppend = pos + w > final
          filtered = filter (> pos) obs

collision :: UI -> Bool
collision ui = next < pos + 6 && next > pos && jumpHeight < 2
    where pos = floor (ui ^. position) + 3
          next = fromMaybe 0 $ headMay (ui ^. obstacles)
          (_, jumpHeight) = ui ^. player

startJump :: Player -> Player
startJump (Types.Level, _) = (Types.Up, 1)
startJump pl = pl

animate :: Player -> Player
animate (Types.Up, pos)
    | pos < 6 = (Types.Up, pos + 1)
    | otherwise = (Types.Down, pos)
animate (Types.Down, pos)
    | pos > 0 = (Types.Down, pos - 1)
    | otherwise = (Types.Level, 0)
animate p = p
