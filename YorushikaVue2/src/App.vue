<template>
  <div id="app">
    <audio id="background-music" autoplay loop>
      <source :src="currentBgm" type="audio/mpeg">
      Your browser does not support the audio element.
    </audio>
    <div id="pageflip-container" style="background-image: url('/YorushikaVue2/background.jpg'); background-size: cover; background-position: center;">
      <!-- First Cover Page -->
      <div class="page page-cover" data-density="hard">
        <div class="page-content">
          <h1>{{ pages[0].content.title }}</h1>
          <p>{{ pages[0].content.body }}</p>
        </div>
      </div>

      <!-- Dynamic Pages -->
      <div v-for="(page, index) in pages.slice(1, pages.length - 1)" :key="index" class="page" :data-type="page.type">
        <div :class="'page-content page-'+index">
          <h1 :key="selectedLanguage">{{ index === 0 && customTitle ? "To " + customTitle : page.content.title }}</h1>
          <p v-if="page.type === 'Text'" :key="selectedLanguage" v-html="convertNewlines(page.content.body)"></p>
          <!-- Change iframe to dynamic player initialization -->
          <div v-if="page.type === 'Video'" ref="videoPlayer" :id="'video-' + index + 1">
            <div :id="`youtube-player-${index + 1}`"></div> <!-- THIS IS DIFFERENT -->
          </div>          
          <img v-if="page.type === 'Image'" :key="selectedLanguage" :src="'/YorushikaVue2/'+page.content.body" alt="Page image" style="max-width:100%; max-height:100%; object-fit:contain;">
        </div>
      </div>

      <!-- Last Cover Page -->
      <div class="page page-cover" data-density="hard">
        <div class="page-content">
          <h1>{{ pages[pages.length - 1].content.title }}</h1>
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
      selectedLanguage: 'en', // Default language
      pageFlip: null,
      pages: pagesData,
      pagesEnData: pagesEnData,
      pagesKrData: pagesKrData,
      pagesJpData: pagesJpData,
      pagesCnData: pagesCnData,
      bgmFiles: {},  // Store preloaded audio objects by filename
      currentBgm: '', // Track the current BGM file
      isMuted: false,
      player: null,
      customTitle: '',          // Title from query string
    };
  },
  mounted() {
    this.customTitle = this.getQueryParam('title') || ''; // Fallback to empty string
    this.$nextTick(() => {
      this.initPageFlip();
      this.preloadBgm();  // Preload all BGM files
      this.updateAudioState(); // Set initial bgm after pageFlip is initialized
      loadYouTubeAPI()
        .then(() => {
          this.updateAudioState(); // Initial BGM state
        })
        .catch((err) => console.error('Error loading YouTube API:', err));
    });
  },
  methods: {
    getQueryParam(param) {
      const urlParams = new URLSearchParams(window.location.search); // Read query string
      return urlParams.get(param); // Return the value of the specified parameter
    },
    getVideoId(url) {
      let languageCode;
      switch (this.selectedLanguage) {
        case 'jp':
          languageCode = 'ja'; // Japanese
          break;
        case 'kr':
          languageCode = 'ko'; // Korean
          break;
        case 'en':
          languageCode = 'en'; // English
          break;
        case 'cn':
          languageCode = 'zh'; // Simplified Chinese (Mandarin)
          break;
        default:
          languageCode = 'en'; // Default to English if no match
          break;
      }
      console.log("video selected language: " + languageCode)
      const videoIdMatch = url.match(/(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|(?:.*[?&]v=))|(?:youtu\.be\/))([\w\-]+)/);
      console.log("video id: " + videoIdMatch[1])
      return videoIdMatch ? videoIdMatch[1] : null;
    },
    convertNewlines(text) {
      return text.replace(/\n/g, '<br>');
    },
    // Preload all BGM files
    preloadBgm() {
      this.pages.forEach((page, index) => {
        if (page.bgm && !this.bgmFiles[page.bgm]) { // Only preload if not already done
          console.log(`Preloading BGM: /music/${page.bgm}`);
          const audio = new Audio(`/YorushikaVue2/music/${page.bgm}`);
          this.bgmFiles[page.bgm] = audio; // Store the audio objects by the BGM filename (e.g., "01.mp3")
        }
      });
    },
    
    getLanguageClass() {
      switch (this.selectedLanguage) {
        case 'en':
          return 'en';
        case 'kr':
          return 'kr';
        case 'jp':
          return 'jp';
        case 'cn':
          return 'cn';
        default:
          return '';
      }
    },
    // Change the language when the user selects a different option
    changeLanguage(event) {
      this.selectedLanguage = event.target.value;
      // Optionally, update pages based on selected language here
      this.updatePageContent();
    },
    updatePageContent() {
      // You can load the corresponding pages data here based on the selected language
      console.log("updatepagecontent: " + this.selectedLanguage)
      switch (this.selectedLanguage) {
        case 'en':
          this.pages = this.pagesEnData;
          break;
        case 'kr':
          this.pages = this.pagesKrData;
          break;
        case 'jp':
          this.pages = this.pagesJpData;
          break;
        case 'cn':
          this.pages = this.pagesCnData;
          break;
      }
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

      // Update audio state after page flip
      this.pageFlip.on('flip', () => {
        this.updateAudioState();
        this.handleVideoPlayer();
      });
    },
    
    updateAudioState() {
      const audioElement = document.getElementById('background-music');
      const currentPage = this.pageFlip.getCurrentPageIndex();
      const nextPage = currentPage + 1;
      const isPortrait = this.pageFlip.getOrientation() === "portrait"; // Portrait mode
      const isLandscape = window.innerWidth > window.innerHeight; // Landscape mode

      console.log(`Current Orientation: ${isPortrait ? 'Portrait' : 'Landscape'}`);

      let visiblePages = [currentPage, nextPage];
      let highestPriorityBgm = this.currentBgm;
      let shouldMute = false;
      if (isPortrait) {
        visiblePages = visiblePages.slice(0, 1)
      }
      // Find the BGM of the visible pages
      visiblePages.forEach((pageIndex) => {
        const page = this.pages[pageIndex];
        if (page && page.type === 'Video') {
          shouldMute = true; // Mute if a video is displayed
        }
        if (page && page.bgm) {
          highestPriorityBgm = page.bgm; // Update the highest priority BGM based on visible pages
        }
      });

      // Check if the selected BGM exists in bgmFiles
      console.log(`Selected BGM: ${highestPriorityBgm}`);
      if (this.bgmFiles[highestPriorityBgm]) {
        // If a new BGM is selected, update and play it
        if (shouldMute) {
          let fadeDuration = 2000; // 2 seconds
          let fadeStep = 0.05; // Decrease volume by 0.05 each step
          let fadeInterval = 50; // Interval time for each fade step (in ms)
          let volume = audioElement.volume;

          // Gradually decrease the volume
          let fadeOutInterval = setInterval(() => {
            if (volume > 0) {
              volume -= fadeStep;  // Reduce volume
              audioElement.volume = volume;  // Set new volume
            } else {
              clearInterval(fadeOutInterval);  // Stop when volume reaches 0
              audioElement.pause();  // Pause the audio
            }
          }, fadeInterval);
        } else if (highestPriorityBgm !== this.currentBgm) {
          this.currentBgm = highestPriorityBgm; // Set the new BGM
          const newBgm = this.bgmFiles[highestPriorityBgm]; // Get the audio object
          audioElement.src = newBgm.src; // Update the audio element's source
          if (audioElement.paused && !this.isMuted) {
            audioElement.play(); // Play the new BGM
          }
        } else if (audioElement.paused) {
          let fadeDuration = 2000; // 2 seconds
          let fadeStep = 0.05; // Decrease volume by 0.05 each step
          let fadeInterval = 50; // Interval time for each fade step (in ms)
          let volume = audioElement.volume;

          // Gradually decrease the volume
          let fadeOutInterval = setInterval(() => {
            if (volume < 1) {
              volume += fadeStep;  // Reduce volume
              audioElement.volume = volume;  // Set new volume
            } else {
              clearInterval(fadeOutInterval);  // Stop when volume reaches 0
              if (!this.isMuted) {
                audioElement.play();
              }  // Pause the audio
            }
          }, fadeInterval);
        }
      } else {
        console.error(`Selected BGM does not exist in bgmFiles: ${highestPriorityBgm}`);
      }
    },
    handleVideoPlayer() {  // THIS IS DIFFERENT: Method to handle video player initialization
      const currentPage = this.pageFlip.getCurrentPageIndex();
      const secondPageNumber = currentPage + 1
      const page = this.pages[currentPage];
      const pageSecond = this.pages[secondPageNumber]
      console.log(currentPage)
      
      // Destroy the previous player if it exists
      if (this.player) {
        this.player.destroy();
        this.player = null;
      }

      let languageCode;
        switch (this.selectedLanguage) {
          case 'jp':
            languageCode = 'ja'; // Japanese
            break;
          case 'kr':
            languageCode = 'ko'; // Korean
            break;
          case 'en':
            languageCode = 'en'; // English
            break;
          case 'cn':
            languageCode = 'zh'; // Simplified Chinese (Mandarin)
            break;
          default:
            languageCode = 'en'; // Default to English if no match
            break;
        }

      console.log("page type: " + page.type)
      console.log("page orientation: " + this.pageFlip.getOrientation())
      const isLandscape = this.pageFlip.getOrientation() === "landscape"
      if (page && page.type === 'Video') {
        console.log("ThisPage:" + currentPage)
        const videoId = this.getVideoId(page.content.body);
              // Set dynamic width and height based on container size or your design logic
        const playerWidth = '100%';  // Or any specific width like '640px'
        const playerHeight = '100%';  // Or a fixed height like '360px'
        // Initialize the YouTube player with specified width and height
        this.player = new YT.Player(`youtube-player-${currentPage}`, {
          videoId: videoId,
          playerVars: {
            'cc_load_policy': 1,  // Show captions by default
            'cc_lang_pref': languageCode,  // Set the captions language
            'autoplay': 1,         // Autoplay video when ready
            'controls': 1,         // Show player controls
          },
          width: playerWidth,         // Set width for the player
          height: playerHeight,       // Set height for the player
          events: {
            onReady: this.onPlayerReady,
            onStateChange: this.onPlayerStateChange,
          },
        });
      } else if(isLandscape) {
        if (pageSecond && pageSecond.type === 'Video') {
          console.log("ThisPage:" + currentPage + 1)
          const videoId = this.getVideoId(pageSecond.content.body);
                // Set dynamic width and height based on container size or your design logic
          const playerWidth = '100%';  // Or any specific width like '640px'
          const playerHeight = '100%';  // Or a fixed height like '360px'
          // Initialize the YouTube player with specified width and height
          this.player = new YT.Player(`youtube-player-${secondPageNumber}`, {
            videoId: videoId,
            playerVars: {
              'cc_load_policy': 1,  // Show captions by default
              'cc_lang_pref': languageCode,  // Set the captions language
              'autoplay': 1,         // Autoplay video when ready
              'controls': 1,         // Show player controls
            },
            width: playerWidth,         // Set width for the player
            height: playerHeight,       // Set height for the player
            events: {
              onReady: this.onPlayerReady,
              onStateChange: this.onPlayerStateChange,
            },
          });
        }
      }
    },
    onPlayerReady(event) {
        const qualities = event.target.getAvailableQualityLevels();
        console.log(qualities)
        if (qualities && qualities.length > 0) {
          event.target.setPlaybackQuality(qualities[0]); // Highest available quality
        } else {
          event.target.setPlaybackQuality('hd1080'); // Default fallback
        }
        event.target.playVideo();
    },
    onPlayerStateChange(event) {
      console.log('Player state changed:', event.data);
    },
    changeLanguage() {
      let languageCode;
      switch (this.selectedLanguage) {
        case 'jp':
          languageCode = 'ja'; // Japanese
          break;
        case 'kr':
          languageCode = 'ko'; // Korean
          break;
        case 'en':
          languageCode = 'en'; // English
          break;
        case 'cn':
          languageCode = 'zh'; // Simplified Chinese (Mandarin)
          break;
        default:
          languageCode = 'en'; // Default to English if no match
          break;
      }
      this.updatePageContent();
      this.setCaptionsLanguage(languageCode);
    },
    setCaptionsLanguage(languageCode) {
      if (this.player) {
        this.player.setOption('captions', 'track', { languageCode });
      }
    },
    // Method to flip to the next page
    flipNext() {
      this.pageFlip.flipNext();
    },

    // Method to flip to the previous page
    flipPrev() {
      this.pageFlip.flipPrev();
    },
    // Toggle BGM mute/unmute
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
    selectedLanguage: 'changeLanguage' // Watch for changes in selected language
  },
};
</script>

<style>
body {
  font-family: serif;
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
  font-size: 14px;
  background-color: #f0f0f0;
  color: #333;
  border: solid 1px #120997;
  border-radius: 5px;
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
  font-family: 'Waiting for the Sunrise', serif;
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
[id^="video-"] {
  height: 60%;
  width: 100%;
}
div.page-content h1 {
  font-family: 'Fredericka the Great', cursive;
  font-weight: 400; /* Ensure the correct weight */
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
.page-content.cover-page h1,
.page-content.cover-page p {
  text-align: center; /* Center-align text on cover pages */
  font-size: clamp(15px, 5vw, 48px);
  margin: 20px 0;     /* Add margin if needed */
}


/* Optional: Adding media queries for further control */
@media (max-width: 768px) {
  .page {
    font-family: 'Waiting for the Sunrise', serif;
    font-size: clamp(15px, 5vw, 48px);
  }
}

@media (max-width: 480px) {
  .page {
    font-family: 'Waiting for the Sunrise', serif;
    font-size: clamp(10px, 2.7vw, 14px);
  }
}
</style>
