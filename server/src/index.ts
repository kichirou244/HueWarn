import { createApp } from './app.js';
import { config } from './config/environment.js';

const { app, cronService } = createApp();

app.listen(config.port, () => {
  process.stdout.write(`HueWarn server listening on port ${config.port}\n`);
  cronService.start();
});
