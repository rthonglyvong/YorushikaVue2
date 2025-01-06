<template>
  <div id="app">
    <audio id="background-music" autoplay loop>
      <source :src="currentBgm" type="audio/mpeg">
      Your browser does not support the audio element.
    </audio>
    <div id="pageflip-container" style="background-image: url('/YorushikaVue/background.jpg'); background-size: cover; background-position: center;">
      <!-- First Cover Page -->
      <div class="page page-cover" data-density="hard">
        <div class="page-content">
          <h2>{{ pages[0].content.title }}</h2>
          <p>{{ pages[0].content.body }}</p>
        </div>
      </div>

      <!-- Dynamic Pages -->
      <div v-for="(page, index) in pages.slice(1, pages.length - 1)" :key="index" class="page" :data-type="page.type">
        <div class="page-content">
          <h2>{{ page.content.title }}</h2>
          <p v-if="page.type === 'Text'" v-html="convertNewlines(page.content.body)"></p>
          <!-- Change iframe to dynamic player initialization -->
          <div v-if="page.type === 'Video'" ref="videoPlayer" :id="'video-' + index">
            <div :id="'youtube-player-' + index"></div> <!-- THIS IS DIFFERENT -->
          </div>
          <img v-if="page.type === 'Image'" :key="selectedLanguage" :src="'/YorushikaVue/'+page.content.body" alt="Page image" style="max-width:100%; max-height:100%; object-fit:contain;">
        </div>
      </div>

      <!-- Last Cover Page -->
      <div class="page page-cover" data-density="hard">
        <div class="page-content">
          <h2>{{ pages[pages.length - 1].content.title }}</h2>
          <p>{{ pages[pages.length - 1].content.body }}</p>
        </div>
      </div>
    </div>
  </div>
  <div class="controls">
    <button id="audio-toggle" @click="toggleBgm">{{ isMuted ? 'Unmute' : 'Mute' }}</button>
    <button @click="flipPrev">Previous</button>
    <button @click="flipNext">Next</button>
    <select v-model="selectedLanguage" @change="changeLanguage">
      <option value="en">English</option>
      <option value="kr">한국어</option>
      <option value="jp">日本語</option>
      <option value="cn">中文</option>
    </select>
  </div>
</template>

<script>
import { PageFlip } from 'page-flip';
import pagesData from '@/content/pages.json';
import pagesEnData from '@/content/pages.en.json';
import pagesKrData from '@/content/pages.kr.json';
import pagesJpData from '@/content/pages.jp.json';
import pagesCnData from '@/content/pages.cn.json';

//load youtube api
function loadYouTubeAPI() {
  return new Promise((resolve, reject) => {
    if (typeof YT !== 'undefined') {
      resolve();
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://www.youtube.com/iframe_api';
    script.async = true;
    script.onload = () => resolve();
    script.onerror = (err) => reject(err);

    document.head.appendChild(script);

    window.onYouTubeIframeAPIReady = () => resolve(); // API is ready
  });
}

export default {
  name: 'App',
  data() {
    return {
      selectedLanguage: 'en',
      pageFlip: null,
      pages: pagesData,
      bgmFiles: {},
      currentBgm: '',
      isMuted: false,
      **player: null,** // THIS IS DIFFERENT: Single player instance
    };
  },
  mounted() {
    this.$nextTick(() => {
      this.initPageFlip();
      loadYouTubeAPI()
        .then(() => {
          this.updateAudioState(); // Initial BGM state
        })
        .catch((err) => console.error('Error loading YouTube API:', err));
    });
  },
  methods: {
    getVideoId(url) {
      let languageCode;
      switch (this.selectedLanguage) {
        case 'jp':
          languageCode = 'ja';
          break;
        case 'kr':
          languageCode = 'ko';
          break;
        case 'en':
          languageCode = 'en';
          break;
        case 'cn':
          languageCode = 'zh';
          break;
        default:
          languageCode = 'en';
          break;
      }

      const videoIdMatch = url.match(/(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|(?:.*[?&]v=))|(?:youtu\.be\/))([\w\-]+)/);
      return videoIdMatch ? videoIdMatch[1] : null;
    },
    convertNewlines(text) {
      return text.replace(/\n/g, '<br>');
    },
    initPageFlip() {
      const container = document.getElementById('pageflip-container');
      this.pageFlip = new PageFlip(container, {
        width: 550,
        height: 733,
        size: 'stretch',
        minWidth: 315,
        maxWidth: 1000,
        minHeight: 420,
        maxHeight: 1350,
        maxShadowOpacity: 0.5,
        flippingTime: 1500,
        showCover: true,
        mobileScrollSupport: true,
        usePortrait: true,
      });

      this.pageFlip.loadFromHTML(container.querySelectorAll('.page'));

      this.pageFlip.on('flip', () => {
        this.updateAudioState();
        **this.handleVideoPlayer();**  // THIS IS DIFFERENT: Dynamically load video player
      });
    },
    updateAudioState() {
      const audioElement = document.getElementById('background-music');
      const currentPage = this.pageFlip.getCurrentPageIndex();
      const nextPage = currentPage + 1;
      const visiblePages = [currentPage, nextPage];

      let highestPriorityBgm = this.currentBgm;

      visiblePages.forEach((pageIndex) => {
        const page = this.pages[pageIndex];
        if (page && page.type === 'Video') {
          // Mute if video is visible
          this.shouldMute = true;
        }
        if (page && page.bgm) {
          highestPriorityBgm = page.bgm;
        }
      });

      if (this.bgmFiles[highestPriorityBgm]) {
        const newBgm = this.bgmFiles[highestPriorityBgm];
        audioElement.src = newBgm.src;
        if (audioElement.paused && !this.isMuted) {
          audioElement.play();
        }
      }
    },
    **handleVideoPlayer() {**  // THIS IS DIFFERENT: Method to handle video player initialization
      const currentPage = this.pageFlip.getCurrentPageIndex();
      const page = this.pages[currentPage];

      // Destroy the previous player if it exists
      if (this.player) {
        this.player.destroy();
        this.player = null;
      }

      if (page && page.type === 'Video') {
        const videoId = this.getVideoId(page.content.body);
        this.player = new YT.Player(`youtube-player-${currentPage}`, {
          videoId: videoId,
          events: {
            onReady: this.onPlayerReady,
            onStateChange: this.onPlayerStateChange,
          },
        });
      }
    },
    onPlayerReady(event) {
      event.target.playVideo();
    },
    onPlayerStateChange(event) {
      console.log('Player state changed:', event.data);
    },
    changeLanguage() {
      this.setCaptionsLanguage(this.selectedLanguage);
    },
    setCaptionsLanguage(languageCode) {
      if (this.player) {
        this.player.setOption('captions', 'track', { languageCode });
      }
    },
    flipNext() {
      this.pageFlip.flipNext();
    },
    flipPrev() {
      this.pageFlip.flipPrev();
    },
    toggleBgm() {
      const audioElement = document.getElementById('background-music');
      this.isMuted = !this.isMuted;
      if (this.isMuted) {
        audioElement.pause();
      } else {
        audioElement.play();
      }
    },
  },
  watch: {
    selectedLanguage: 'changeLanguage', // Watch for changes in selected language
  },
};
</script>

<style scoped>
body {
  font-family: Arial, sans-serif;
  margin: 0;
  padding: 0;
  box-sizing: border-box; /* Apply box-sizing globally */
  align-items: center;      /* Vertically center the #app */
  display: flex;

}
#app {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  width: 100vw;
  overflow: hidden;
  background-color: #f4f4f4;
  margin: 0;
  padding: 0;
  height: 100%;  /* Ensures #app takes up the full height of the screen */
  width: 100%;
  box-sizing: border-box; 
}
.controls {
  position: fixed;       /* Fixes the controls to the bottom of the screen */
  left: 0;
  right: 0;
  bottom: 0;             /* Sticks it to the bottom */
  background-color: rgba(0, 0, 0, 0.5);  /* Optional: Add background to make it stand out */
  color: white;          /* Text color */
  padding: 10px;         /* Padding inside the controls */
  text-align: center;    /* Center the text inside the controls */
  z-index: 10;           /* Ensure it stays on top of other content */
}
button {
  margin: 5px;
  padding: 10px 20px;
  cursor: pointer;
}
.flip-book {
  box-shadow: 0 0 20px 0 rgba(0, 0, 0, 0.5);
  display: none;
  background-size: cover;
}
.page {
  padding: 20px;
  background-color: hsl(35, 55%, 98%);
  color: #274C77;
  border: solid 1px hsl(35, 20%, 70%);
  overflow: hidden;
  font-family: 'Patrick Hand', cursive;
  font-size: clamp(12px, 5vw, 17px);
  line-height: 1.6;
  text-align: center;
}
.page-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  width: 100%;
  text-align: center;
}

select {
  margin: 5px;
  padding: 10px 20px;
  cursor: pointer;
  font-size: 14px;
  background-color: #f0f0f0;
  color: #333;
  border: solid 1px #120997;
  border-radius: 5px;
  appearance: none; /* Removes default dropdown arrow */
  -webkit-appearance: none; /* Removes dropdown for Safari */
  -moz-appearance: none; /* Removes dropdown for Firefox */
}

.page-content p {
  text-align: left; /* Left justify the text */
  word-wrap: break-word;
  word-break: break-word;
  line-height: 1.6;   /* Improve readability */
  margin: 10px 0;     /* Add spacing around the paragraph */
}
.page-content.cover-page h2,
.page-content.cover-page p {
  text-align: center; /* Center-align text on cover pages */
  font-size: clamp(15px, 5vw, 48px);
  margin: 20px 0;     /* Add margin if needed */
}


@media (max-width: 768px) {
  .page {
    font-size: clamp(15px, 5vw, 48px);
  }
}

@media (max-width: 480px) {
  .page {
    font-size: clamp(10px, 2.7vw, 14px);
  }
}
</style>
