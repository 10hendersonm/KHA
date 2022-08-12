;(async () => {
  const pkg = require('./package.json')

  const path = require('path')
  const os = require('os')
  const { execSync } = require('child_process')

  const findit = require('findit')
  const fs = require('fs-extra')

  const addonFiles = path.join(__dirname, 'src')

  console.log('Locating WoW...')

  const getDiskCommand = 'wmic logicaldisk get name'
  const disks = execSync(`cmd /C "${getDiskCommand}"`)
    .toString('utf-8')
    .trim()
    .split(os.EOL)
    .map((line) => line.trim())
    .filter((line) => line.length)
    .filter((line) => /^[a-z]:$/i.test(line))
    .map((line) => `${line}/`)

  const ignoreDirectories = ['Windows'].map((dir) => dir.toLowerCase())

  const finders = []

  let installLocation

  for (const disk of disks) {
    if (!fs.existsSync(disk)) {
      continue
    }

    const finder = findit(disk)
    finder.on('directory', (dir, stat, stop) => {
      const base = path.basename(dir)

      if (ignoreDirectories.includes(base.toLowerCase())) {
        stop()
      }

      if (base.toLowerCase() == 'World of Warcraft'.toLowerCase()) {
        const classicAddonPath = path.join(
          dir,
          '_classic_',
          'Interface',
          'AddOns'
        )

        if (fs.existsSync(classicAddonPath)) {
          installLocation = classicAddonPath
          console.log(`Located WoW at ${dir}`)
          finders.forEach((finder) => {
            finder.stop()
          })
        }
      }
    })
    finder.on('error', () => {
      // ignore it
    })

    finders.push(finder)
  }

  await Promise.all(
    finders.map(
      (finder) =>
        new Promise((resolve) => {
          finder.on('end', resolve)
          finder.on('stop', resolve)
        })
    )
  )

  if (!installLocation) {
    console.log('World of Warcraft was not found :(')
    return process.exit(1)
  }

  const outPath = path.join(installLocation, pkg.name)
  console.log(`Copying addon files to ${outPath}`)
  await fs.copy(addonFiles, outPath, {
    recursive: true,
    overwrite: true,
  })

  console.log('--- Done ---')
  return process.exit(0)
})()
