/* eslint-disable react-hooks/exhaustive-deps */
import { Button, Input, Divider, Tag } from 'antd';
import { MemoryRouter as Router, Route, Routes } from 'react-router-dom';
import './App.css';
import axios from 'axios';
import { ChangeEvent, useEffect, useState, useRef } from 'react';
import constants from '../lib/constants';

const { characterRankings } = constants;

const clickEvent = new MouseEvent('click', {
  button: 0,
})

const host = 'http://127.0.0.1:5000';

const Core = () => {
  const [characterPredictions, setCharacterPredictions] = useState([]);
  const [wordPredictions, setWordPredictions] = useState([]);
  const [inputData, setInputData] = useState('');
  const buttonTest = useRef<HTMLInputElement>(null)
  const predictNextCharacter = async () => {
    const text = `${host}?text=${inputData.length > 0 ? inputData : ''}`;
    console.log({ request: text });
    axios
      .get(text)
      .then((res) => {
        const { nextCharactersRanked, wordList } = res.data;

        // console.log({ wordList });

        setCharacterPredictions(nextCharactersRanked);
        setWordPredictions(wordList);

        return res;
      })
      .catch((res) => {
        console.error(res);
      });



      buttonTest.current?.children[0].firstChild?.dispatchEvent(clickEvent)

      console.log( buttonTest.current?.children[0].firstChild)
  };

  useEffect(() => {
    predictNextCharacter();
  }, [inputData]);

  const handleInputChange = (e: ChangeEvent<HTMLInputElement>) => {
    setInputData(e.target.value);
  };

  return (
    <div>
      <Input value={inputData} size="large" onChange={handleInputChange} />
      <Divider />
      {wordPredictions.map((i: any) => (
        <Tag onClick={() => setInputData(i.sequence.replace('.', ''))}>
          {i.sequence.replace('.', '')}
        </Tag>
      ))}
      <Divider />
      <div ref={buttonTest} className="button-container">
        {inputData.length < 2
          ? Object.keys(characterRankings).map((i) => (
              <div key={`_${i}`} className="button-box">
                <Button
                  onClick={() => {
                    const text = `${inputData}${i}`;
                    setInputData(text);
                  }}
                  type="primary"
                  size="large"
                >
                  {i}
                </Button>
              </div>
            ))
          : characterPredictions.map((i: any) => (
              <div key={`_${i.char}`} className="button-box">
                <Button
                  onClick={() => {
                    const text = `${inputData}${i.char}`;
                    setInputData(text);
                  }}
                  type="primary"
                  size="large"
                >
                  {i.char}
                </Button>
              </div>
            ))}
      </div>
      <Divider />
    </div>
  );
};

export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Core />} />
      </Routes>
    </Router>
  );
}
