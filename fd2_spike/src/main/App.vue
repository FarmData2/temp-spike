<script setup>
import HelloWorld from '../components/HelloWorld/HelloWorld.vue'
import TheWelcome from '../components/TheWelcome/TheWelcome.vue'
import dayjs from 'dayjs'
</script>

<script>
export default {
  data() {
    return {
      date: '1/1/2022',
    }
  },
  computed: {
    formatDate() {
      return dayjs(this.date).format('YYYY-MM-DD')
    },
  },
}
</script>

<template>
  <header>
    <img alt="Vue logo" class="logo" src="../assets/logo.svg" width="125" height="125" />

    <div class="wrapper">
      <HelloWorld msg="This is the `main` module!" />
    </div>
  </header>

  <main>
    <TheWelcome />
    <br />
    <div>{{ formatDate }}</div>
  </main>
</template>

<style scoped>
header {
  line-height: 1.5;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  .logo {
    margin: 0 2rem 0 0;
  }

  header .wrapper {
    display: flex;
    place-items: flex-start;
    flex-wrap: wrap;
  }
}
</style>
